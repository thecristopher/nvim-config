#!/usr/bin/env python3
"""Builds the synthesized franchise sounds into sounds/<franchise>/<event>.wav.

Tones and noise are synthesized here and ffmpeg adds the room (echo, filters). The clips from the
games live next to them and are left alone. Only the standard library is needed, plus ffmpeg.

Usage:
    python3 scripts/sounds.py                 # every franchise
    python3 scripts/sounds.py resident_evil   # just one
    python3 scripts/sounds.py --clips         # finish the game clips listed in CLIPS
    python3 scripts/sounds.py --import ~/Downloads/clip.mp3 elden_ring bought
"""

import glob
import math
import os
import random
import shutil
import struct
import subprocess
import sys
import tempfile
import wave

RATE = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "sounds")
# every sound peaks here, quiet enough to never startle anyone mid session
PEAK = 0.45


# ── building blocks ──────────────────────────────────────────────────────────────


def silence(seconds):
    """Returns seconds of nothing."""
    return [0.0] * int(seconds * RATE)


def tone(freq, seconds, shape="sine", glide_to=None):
    """Returns an oscillator, optionally gliding to another frequency.

    Args:
        freq: starting frequency in Hz.
        seconds: length.
        shape: sine, saw, square or triangle.
        glide_to: frequency reached at the end, None keeps it steady.
    """
    count = int(seconds * RATE)
    out, phase = [], 0.0
    for index in range(count):
        current = freq if glide_to is None else freq + (glide_to - freq) * index / count
        phase = (phase + current / RATE) % 1.0
        out.append(_shape(shape, phase))
    return out


def _shape(shape, phase):
    if shape == "saw":
        return 2.0 * phase - 1.0
    if shape == "square":
        return 1.0 if phase < 0.5 else -1.0
    if shape == "triangle":
        return 4.0 * abs(phase - 0.5) - 1.0
    return math.sin(2 * math.pi * phase)


def noise(seconds, seed=7):
    """Returns white noise, seeded so every build sounds the same."""
    rng = random.Random(seed)
    return [rng.uniform(-1.0, 1.0) for _ in range(int(seconds * RATE))]


def envelope(samples, attack=0.01, release=0.2, curve=1.0):
    """Fades a sound in over attack seconds and out over release seconds."""
    count = len(samples)
    rise, fall = max(1, int(attack * RATE)), max(1, int(release * RATE))
    out = []
    for index, value in enumerate(samples):
        gain = min(1.0, index / rise, (count - index) / fall)
        out.append(value * max(0.0, gain) ** curve)
    return out


def decay(samples, seconds):
    """Lets a struck sound ring out, losing most of its energy over seconds."""
    return [value * math.exp(-index / (seconds * RATE)) for index, value in enumerate(samples)]


def lowpass(samples, cutoff):
    """One pole lowpass, cutoff in Hz, or a function of the sample index for sweeps."""
    out, last = [], 0.0
    for index, value in enumerate(samples):
        freq = float(cutoff(index)) if callable(cutoff) else float(cutoff)
        alpha = 1.0 - math.exp(-2 * math.pi * freq / RATE)
        last += alpha * (value - last)
        out.append(last)
    return out


def highpass(samples, cutoff):
    """One pole highpass, the noise left once the lowpass is taken away."""
    low = lowpass(samples, cutoff)
    return [value - smooth for value, smooth in zip(samples, low)]


def mix(*layers):
    """Adds layers together, (samples, gain, offset_seconds) each."""
    length = max(int(offset * RATE) + len(samples) for samples, _, offset in layers)
    out = [0.0] * length
    for samples, gain, offset in layers:
        start = int(offset * RATE)
        for index, value in enumerate(samples):
            out[start + index] += value * gain
    return out


def chord(freqs, seconds, shape="saw", detune=0.004):
    """Stacks detuned voices for every frequency, the way an ensemble sounds wide."""
    voices = []
    for freq in freqs:
        for spread in (-detune, 0.0, detune):
            voices.append((tone(freq * (1 + spread), seconds, shape), 1.0 / (len(freqs) * 3), 0.0))
    return mix(*voices)


def bell(freq, seconds):
    """A struck bell: a few inharmonic partials ringing out at their own pace."""
    partials = [(1.0, 1.0, 1.0), (2.76, 0.5, 0.6), (5.4, 0.25, 0.35), (8.9, 0.12, 0.2)]
    # partials near the top of hearing only add a harsh fizz, so they stay out
    audible = [partial for partial in partials if freq * partial[0] < 15000]
    layers = [(decay(tone(freq * ratio, seconds), seconds * life), gain, 0.0) for ratio, gain, life in audible]
    return envelope(mix(*layers), attack=0.002, release=seconds * 0.3)


def thump(freq, seconds):
    """A low hit with a pitch drop, a heartbeat or a door slamming shut."""
    body = decay(tone(freq * 1.8, seconds, glide_to=freq), seconds * 0.25)
    click = decay(lowpass(noise(seconds, seed=int(freq)), 900), seconds * 0.05)
    return envelope(mix((body, 1.0, 0.0), (click, 0.4, 0.0)), attack=0.002, release=0.05)


# ── recipes ──────────────────────────────────────────────────────────────────────
# Each returns (samples, ffmpeg filter).

# a big hall: three echoes, each further and fainter
HALL = "aecho=0.8:0.8:90|240|520:0.45|0.3|0.18"
ROOM = "aecho=0.8:0.6:40|110:0.35|0.18"


def re_boss():
    # a heartbeat that quickens while heavy steps come closer
    layers, at = [], 0.0
    for gap in (0.62, 0.55, 0.48, 0.42):
        layers += [(thump(52, 0.35), 0.9, at), (thump(48, 0.3), 0.6, at + 0.14)]
        at += gap
    for step, when in enumerate((0.3, 0.95, 1.55)):
        layers.append((lowpass(decay(noise(0.4, seed=40 + step), 0.08), 220), 0.7 + 0.15 * step, when))
    return mix(*layers), ROOM


def re_felled():
    # the item pickup chirp, two notes up
    first = envelope(tone(880, 0.09, "square"), 0.004, 0.03)
    second = envelope(tone(1320, 0.22, "square"), 0.004, 0.15)
    return lowpass(mix((first, 0.5, 0.0), (second, 0.5, 0.1)), 3600), ROOM


def re_great():
    # mission complete: a rising arpeggio that lands on a held chord
    notes = [523.25, 659.25, 783.99, 1046.5]
    layers = [(envelope(tone(freq, 0.16, "square"), 0.005, 0.08), 0.35, index * 0.12) for index, freq in enumerate(notes)]
    held = envelope(lowpass(chord([523.25, 659.25, 783.99], 1.6, "saw"), 2400), 0.05, 0.9)
    layers.append((held, 0.8, 0.5))
    return mix(*layers), HALL


def re_cleansed():
    # containment: a filter sweep falling away, then a clean confirm chime
    sweep = envelope(lowpass(noise(1.0, seed=21), lambda index: 3000 * math.exp(-index / 12000.0) + 120), 0.02, 0.4)
    return mix((sweep, 0.7, 0.0), (bell(1568, 1.0), 0.45, 0.55)), ROOM


def re_region():
    # a new location: a low swell and the click of the map
    swell = envelope(lowpass(chord([55.0, 82.41], 1.5, "saw"), 260), attack=0.6, release=0.6)
    click = decay(highpass(noise(0.05, seed=5), 2000), 0.01)
    return mix((swell, 0.9, 0.0), (click, 0.6, 1.2)), ROOM


def er_choir_pad(freqs, seconds, brightness):
    """Detuned saws through a slowly opening filter, the closest thing to a choir from scratch."""
    pad = chord(freqs, seconds, "saw", detune=0.006)
    count = len(pad)
    return lowpass(pad, lambda index: 250 + brightness * index / count)


def er_great():
    swell = envelope(er_choir_pad([98.0, 146.83, 196.0, 246.94, 293.66], 3.0, 3200), attack=0.7, release=1.2)
    timpani = thump(65, 1.0)
    return mix((timpani, 0.9, 0.0), (swell, 0.9, 0.1), (timpani, 0.6, 0.45)), HALL


def er_cleansed():
    whoosh = envelope(lowpass(noise(1.2, seed=31), lambda index: 300 + 4000 * index / (1.2 * RATE)), 0.5, 0.4)
    return mix((whoosh, 0.6, 0.0), (bell(1046.5, 1.4), 0.4, 0.8)), HALL


def er_fog():
    # wind through the fog wall, rising and passing
    wind = lowpass(noise(1.5, seed=13), lambda index: 500 + 700 * math.sin(math.pi * index / (1.5 * RATE)))
    return envelope(wind, attack=0.5, release=0.7), ROOM


def er_boss():
    drums = [(thump(55, 0.5), 0.9, at) for at in (0.0, 0.4, 0.8, 1.0, 1.2)]
    strings = [value * (0.6 + 0.4 * math.sin(index / 400.0)) for index, value in enumerate(er_choir_pad([73.42, 110.0, 146.83], 1.9, 1400))]
    return mix((envelope(strings, 0.6, 0.4), 0.7, 0.0), *drums), HALL


def er_region():
    gong = bell(110, 2.4)
    pad = envelope(er_choir_pad([220.0, 329.63], 2.2, 1200), attack=0.6, release=0.9)
    return mix((gong, 0.6, 0.0), (pad, 0.6, 0.15)), HALL


# Elizabeth: a dressing room and a stage. Music box notes, velvet curtains, applause and the
# clapperboard, with a heartbeat for the villain.
STAGE = "aecho=0.8:0.7:60|160|340:0.4|0.25|0.12"

# notes by name, so the melodies read like a score
NOTE = {
    "C5": 523.25, "D5": 587.33, "E5": 659.25, "F5": 698.46, "G5": 783.99, "A5": 880.0,
    "B5": 987.77, "C6": 1046.5, "D6": 1174.66, "E6": 1318.51, "G6": 1567.98, "A4": 440.0,
    "E4": 329.63, "C4": 261.63, "G4": 392.0, "A3": 220.0,
}


def music_box(name, seconds=1.2):
    """A music box tine: a bright bell with a quick fade."""
    return decay(bell(NOTE[name], seconds), seconds * 0.35)


def melody(names, gap, seconds=1.2):
    """Plays notes one after another, gap seconds apart."""
    return mix(*[(music_box(name, seconds), 0.6, index * gap) for index, name in enumerate(names)])


def clap(seed):
    """One hand clap: a short burst of bright noise."""
    burst = decay(noise(0.06, seed=seed), 0.012)
    return lowpass(highpass(burst, 700), 4200)


def applause(seconds, density, seed=3):
    """A crowd clapping, density claps per second scattered at random."""
    rng = random.Random(seed)
    layers = [(silence(seconds), 1.0, 0.0)]
    for index in range(int(seconds * density)):
        when = rng.uniform(0.0, seconds)
        # the crowd swells in and settles out
        swell = math.sin(math.pi * when / seconds)
        layers.append((clap(seed * 1000 + index), 0.25 + 0.5 * swell, when))
    return mix(*layers)


def velvet(seconds, seed, rising=True):
    """Heavy fabric sliding along a rail: low noise whose brightness rises or falls."""
    span = seconds * RATE

    def cutoff(index):
        into = index / span
        return 180 + 900 * (into if rising else 1 - into)

    return envelope(lowpass(noise(seconds, seed=seed), cutoff), attack=0.15, release=0.3)


def clapper():
    """The clapperboard snapping shut: two hard clicks a hair apart."""
    snap = decay(highpass(noise(0.05, seed=77), 1500), 0.006)
    body = decay(tone(180, 0.08, glide_to=90), 0.02)
    return mix((snap, 1.0, 0.0), (body, 0.6, 0.0), (snap, 0.7, 0.025))


# short sounds that follow every keypress: built dry and quiet, loudnorm cannot measure them
UI = {"pad": 0.05, "loudness": None, "gain": -6, "trim": True}
# moments: their echo trimmed so nothing rings longer than the banner it belongs to
MOMENT = {"trim": True}
DRY = "anull"
LITTLE_ROOM = "aecho=0.8:0.5:30:0.18"


def tine(freq, seconds):
    """One music box tine at any pitch, struck and gone."""
    return decay(bell(freq, seconds), seconds * 0.3)


def el_title():
    # the overture: strings swell through four chords while the music box plays her theme
    chords = [[261.63, 329.63, 392.0], [220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [196.0, 246.94, 293.66]]
    pads = [(envelope(er_choir_pad(chord, 2.0, 1500), attack=0.5, release=0.8), 0.32, index * 1.6)
            for index, chord in enumerate(chords)]
    theme = melody(["E5", "G5", "C6", "B5", "A5", "C6", "G5", "E5", "F5", "A5", "G5", "D6", "C6"], 0.48, 1.8)
    final = envelope(er_choir_pad([261.63, 329.63, 392.0, 523.25], 2.4, 2200), attack=0.3, release=1.6)
    sparkle = melody(["C6", "E6", "G6"], 0.08, 1.2)
    return mix(*pads, (theme, 0.9, 0.2), (final, 0.4, 6.4), (sparkle, 0.5, 6.4)), STAGE, MOMENT


def el_curtain():
    # timed to the animation: the drapes close by 0.9 s, the stage is announced, they part at 1.6 s
    closing = mix((velvet(0.9, 11, rising=True), 0.8, 0.0), (velvet(0.9, 12, rising=True), 0.6, 0.05))
    meet = thump(70, 0.3)
    announce = mix((tine(NOTE["C6"], 0.9), 0.5, 0.0), (tine(NOTE["E6"], 0.9), 0.4, 0.0))
    opening = mix((velvet(1.0, 13, rising=False), 0.8, 0.0), (velvet(1.0, 14, rising=False), 0.6, 0.04))
    layers = [(closing, 1.0, 0.0), (meet, 0.5, 0.86), (announce, 0.6, 1.1), (opening, 1.0, 1.6)]
    return mix(*layers), ROOM, MOMENT


def el_rest():
    # a lullaby long enough to nap to: two phrases and their answer over a soft pad, it stops when she wakes you
    phrase = ["E5", "C5", "D5", "G4", "C5", "E5", "D5", "C5"]
    answer = ["A4", "C5", "E5", "D5", "C5", "B5", "G5", "C5"]
    tune = phrase + phrase + answer + phrase
    lullaby = melody(tune, 0.62, 2.2)
    length = len(tune) * 0.62 + 2.0
    pad = envelope(er_choir_pad([130.81, 196.0, 261.63], length, 700), attack=3.0, release=4.0)
    return mix((lullaby, 0.8, 0.0), (pad, 0.18, 0.0)), STAGE, MOMENT


def el_grace():
    # a new stage found, and every time Claude finishes: short, bright, never in the way
    return melody(["C5", "E5", "G5", "C6", "E6"], 0.09, 1.1), STAGE, MOMENT


def el_bought():
    # the till of the costume shop: a bright ka-ching and the drawer
    ka = decay(highpass(noise(0.04, seed=61), 2500), 0.008)
    ching = mix((tine(2093.0, 0.9), 0.7, 0.0), (tine(2637.0, 0.9), 0.5, 0.02))
    drawer = lowpass(decay(noise(0.12, seed=62), 0.04), 600)
    return mix((ka, 0.6, 0.0), (ching, 1.0, 0.05), (drawer, 0.4, 0.2)), LITTLE_ROOM, MOMENT


def el_welcome():
    # the bell over the costume shop's door, a little jingle as it swings
    strikes = mix((tine(1318.5, 1.2), 0.7, 0.0), (tine(1046.5, 1.2), 0.6, 0.18))
    jingle = mix(*[(tine(2400.0 + 180 * index, 0.25), 0.18, 0.04 * index) for index in range(6)])
    return mix((strikes, 1.0, 0.0), (jingle, 1.0, 0.02)), STAGE, MOMENT


def el_merchant():
    # the wardrobe assistant answering: a soft ding dong
    return melody(["E6", "C6"], 0.22, 1.1), STAGE, MOMENT


def el_weapon():
    # a pass she loved: a short round of applause and a whistle from the wings
    whistle = mix(
        (envelope(tone(1400, 0.18, glide_to=2300), 0.01, 0.05), 0.5, 0.0),
        (envelope(tone(1500, 0.3, glide_to=1100), 0.01, 0.1), 0.5, 0.25),
    )
    return mix((applause(1.2, 34, seed=29), 0.8, 0.0), (whistle, 0.35, 0.3)), STAGE, MOMENT


def el_expedition():
    # the clapperboard calls the take and the set goes quiet
    hush = envelope(lowpass(noise(1.4, seed=31), lambda index: 1200 - 900 * index / (1.4 * RATE)), 0.05, 1.0)
    return mix((clapper(), 1.0, 0.0), (hush, 0.25, 0.2)), ROOM, MOMENT


def el_hud_open():
    # the dressing room door: a quick swish of the curtain and a bright tine
    swish = velvet(0.22, 41, rising=True)
    return mix((swish, 0.7, 0.0), (tine(NOTE["C6"], 0.35), 0.5, 0.14)), LITTLE_ROOM, dict(UI, gain=0)


def el_hud_close():
    swish = velvet(0.22, 43, rising=False)
    return mix((swish, 0.7, 0.0), (tine(NOTE["G5"], 0.35), 0.45, 0.1)), LITTLE_ROOM, dict(UI, gain=0)


def el_hud_move():
    # browsing the rack: the softest tick of a hanger on the rail
    tick = decay(highpass(noise(0.02, seed=47), 3000), 0.003)
    hanger = tine(2637.0, 0.08)
    return mix((tick, 0.5, 0.0), (hanger, 0.25, 0.0)), DRY, dict(UI, gain=-12)


def el_hud_select():
    return tine(NOTE["C6"], 0.4), DRY, dict(UI, gain=-9)


def el_hud_back():
    return mix((tine(NOTE["G5"], 0.35), 0.8, 0.0), (tine(NOTE["E5"], 0.35), 0.5, 0.07)), DRY, dict(UI, gain=-9)


def el_boss():
    layers, at = [], 0.0
    for gap in (0.7, 0.6, 0.5, 0.42, 0.36):
        layers += [(thump(50, 0.35), 0.9, at), (thump(46, 0.3), 0.55, at + 0.16)]
        at += gap
    dread = envelope(lowpass(chord([110.0, 116.54], at + 0.5, "saw"), 500), attack=0.8, release=0.6)
    return mix((dread, 0.5, 0.0), *layers), STAGE


def el_felled():
    return mix((applause(1.6, 40, seed=5), 0.8, 0.0), (music_box("G6", 1.0), 0.5, 0.05)), STAGE


def el_great():
    crowd = applause(3.2, 70, seed=9)
    swell = envelope(er_choir_pad([261.63, 329.63, 392.0, 523.25], 3.0, 2600), attack=0.6, release=1.2)
    return mix((crowd, 0.9, 0.0), (swell, 0.55, 0.2), (melody(["C6", "E6", "G6"], 0.14), 0.5, 0.3)), STAGE


def el_died():
    falling = melody(["E5", "C5", "A4", "E4"], 0.32, 1.6)
    return mix((clapper(), 1.0, 0.0), (falling, 0.7, 0.35)), STAGE


def el_cleansed():
    sparkle = melody(["G5", "B5", "D6", "G6"], 0.07, 1.0)
    shimmer = envelope(lowpass(noise(1.0, seed=17), lambda index: 2000 + 3000 * index / RATE), 0.3, 0.5)
    return mix((sparkle, 0.8, 0.0), (highpass(shimmer, 1800), 0.2, 0.1)), STAGE


def el_region():
    swish = velvet(0.6, 21, rising=True)
    return mix((swish, 0.7, 0.0), (melody(["A4", "C5", "E5"], 0.09, 1.4), 0.7, 0.45)), STAGE


def el_zone():
    return music_box("E6", 1.4), STAGE


def el_phantom():
    pad = envelope(er_choir_pad([440.0, 554.37, 659.25], 2.0, 1400), attack=1.2, release=0.7)
    return pad, STAGE


def el_continue():
    return melody(["G5", "C6"], 0.18, 1.4), STAGE


def el_summon():
    return melody(["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6"], 0.06, 1.2), STAGE


def el_comfort():
    return melody(["E5", "C5"], 0.35, 1.6), STAGE


# Elden Ring's menus: a soft stone tok and small bells, quiet enough for every keypress
def er_hud_move():
    tok = lowpass(decay(noise(0.03, seed=81), 0.006), 1800)
    return mix((tok, 0.7, 0.0), (decay(bell(1760.0, 0.08), 0.02), 0.2, 0.0)), DRY, dict(UI, gain=-12)


def er_hud_select():
    return mix((decay(bell(1318.5, 0.4), 0.12), 0.8, 0.0), (thump(110, 0.12), 0.2, 0.0)), DRY, dict(UI, gain=-9)


def er_hud_back():
    return decay(bell(880.0, 0.35), 0.1), DRY, dict(UI, gain=-9)


def er_hud_open():
    whoosh = envelope(lowpass(noise(0.3, seed=83), lambda index: 300 + 2500 * index / (0.3 * RATE)), 0.05, 0.12)
    return mix((whoosh, 0.6, 0.0), (decay(bell(1046.5, 0.4), 0.12), 0.5, 0.18)), LITTLE_ROOM, dict(UI, gain=0)


def er_hud_close():
    whoosh = envelope(lowpass(noise(0.3, seed=85), lambda index: 2800 - 2500 * index / (0.3 * RATE)), 0.03, 0.15)
    return mix((whoosh, 0.6, 0.0), (decay(bell(659.25, 0.4), 0.12), 0.45, 0.12)), LITTLE_ROOM, dict(UI, gain=0)


def er_comfort():
    # failing the same trial again: the choir sighs and settles, no judgment in it
    sigh = envelope(er_choir_pad([220.0, 261.63, 329.63], 1.8, 900), attack=0.3, release=1.0)
    rest = envelope(er_choir_pad([196.0, 246.94, 293.66], 1.6, 700), attack=0.4, release=1.0)
    return mix((sigh, 0.7, 0.0), (rest, 0.6, 0.9)), HALL, MOMENT


def er_expedition():
    # the last sound before the Lands Between go quiet: a deep gong and a breath of choir fading out
    gong = bell(73.42, 2.6)
    breath = envelope(er_choir_pad([146.83, 220.0], 2.0, 600), attack=0.2, release=1.6)
    return mix((gong, 0.8, 0.0), (breath, 0.4, 0.05)), HALL, MOMENT


# Raccoon City's quiet new area chime: two soft square tones through a radio filter
def re_zone():
    first = envelope(tone(659.25, 0.12, "square"), 0.005, 0.06)
    second = envelope(tone(987.77, 0.3, "square"), 0.005, 0.2)
    return lowpass(mix((first, 0.5, 0.0), (second, 0.5, 0.13)), 2200), ROOM, {"trim": True}


RECIPES = {
    # title, door, rest (the save room), continue, grace (the typewriter saving), died (game over), merchant,
    # bought, welcome, weapon, summon, comfort, expedition and the hud_ inventory sounds are clips from the game, so they are not built here
    "resident_evil": {
        "boss": re_boss, "felled": re_felled, "great": re_great, "cleansed": re_cleansed,
        "region": re_region, "zone": re_zone,
    },
    # title, died, felled, grace, rest, zone, merchant, phantom and continue are clips from the game, so they are not built here
    "elden_ring": {
        "great": er_great, "cleansed": er_cleansed,
        "fog": er_fog, "boss": er_boss, "region": er_region,
        "comfort": er_comfort, "expedition": er_expedition,
        "hud_open": er_hud_open, "hud_close": er_hud_close, "hud_move": er_hud_move,
        "hud_select": er_hud_select, "hud_back": er_hud_back,
    },
    # every one of hers is built here, nothing is a clip
    "elizabeth": {
        "title": el_title, "curtain": el_curtain, "rest": el_rest, "boss": el_boss,
        "felled": el_felled, "great": el_great, "died": el_died, "grace": el_grace,
        "cleansed": el_cleansed, "region": el_region, "zone": el_zone, "phantom": el_phantom,
        "continue": el_continue, "summon": el_summon, "comfort": el_comfort, "bought": el_bought,
        "welcome": el_welcome, "merchant": el_merchant, "weapon": el_weapon,
        "expedition": el_expedition, "hud_open": el_hud_open, "hud_close": el_hud_close,
        "hud_move": el_hud_move, "hud_select": el_hud_select, "hud_back": el_hud_back,
    },
}


# ── clips ────────────────────────────────────────────────────────────────────────
# The events that are clips from the games, finished so each fits its moment: the silence before
# and after is cut, anything longer than max seconds fades out there, and every one is evened out
# to the loudness the built sounds share (HUD clips stay quieter, they follow every keypress).

CLIPS = {
    "elden_ring": {
        "title": {}, "rest": {}, "summon": {}, "merchant": {}, "zone": {},
        "felled": {"max": 4.0}, "died": {"max": 5.5}, "continue": {"max": 4.0},
        "grace": {"max": 3.5}, "phantom": {"max": 3.5},
        "bought": {"max": 3.0}, "welcome": {}, "weapon": {},
    },
    "resident_evil": {
        "title": {}, "continue": {}, "comfort": {}, "grace": {}, "door": {}, "expedition": {},
        "merchant": {}, "welcome": {}, "bought": {}, "weapon": {"max": 4.0},
        "died": {"max": 5.5}, "rest": {"loudness": -26}, "phantom": {}, "summon": {},
        "hud_open": {"loudness": None}, "hud_close": {"loudness": None},
        "hud_move": {"loudness": None}, "hud_select": {"loudness": None},
        "hud_back": {"loudness": None},
    },
}

# the clip finishing everything starts from: trims both ends, evens out to the moments' loudness
CLIP_FINISH = {"max": None, "fade": 0.8, "loudness": -24}
LEAD = "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.02"


def duration_of(path):
    """Returns how long a sound lasts in seconds, read by ffprobe."""
    output = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
        check=True, capture_output=True, text=True,
    ).stdout
    return float(output.strip())


def clip_filters(path, finish):
    """The filter chain that finishes a clip: both ends trimmed, a fade when it runs too long."""
    steps = [LEAD, TRIM]
    if finish["max"] and duration_of(path) > finish["max"] + 0.05:
        start = finish["max"] - finish["fade"]
        steps += [f"atrim=0:{finish['max']}", f"afade=t=out:st={start}:d={finish['fade']}"]
    return steps


def refine(path, finish, scratch):
    """Finishes a clip in place, safe to run again: a trimmed clip has nothing left to trim."""
    finish = {**CLIP_FINISH, **finish}
    staged = os.path.join(scratch, "staged.wav")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-af", ",".join(clip_filters(path, finish)),
         "-ac", "1", "-ar", str(RATE), staged],
        check=True,
    )
    level(staged, scratch, {"loudness": finish["loudness"], "gain": 0})
    target = os.path.splitext(path)[0] + ".wav"
    shutil.move(staged, target)
    if target != path:
        os.remove(path)


def clip_path(franchise, event):
    """Returns the file an event plays in a franchise, whatever its extension, None when missing."""
    found = sorted(glob.glob(os.path.join(ROOT, franchise, event + ".*")))
    return found[0] if found else None


def refine_clips(scratch):
    """Finishes every clip listed in CLIPS."""
    for franchise, events in CLIPS.items():
        for event, finish in events.items():
            path = clip_path(franchise, event)
            if not path:
                print(f"{franchise}/{event} has no clip yet")
                continue
            refine(path, finish, scratch)
            print(f"{franchise}/{event}.wav finished")


def import_clip(source, franchise, event, scratch):
    """Copies a clip into sounds/<franchise>/<event>.wav and finishes it like the rest."""
    target = os.path.join(ROOT, franchise, event + ".wav")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source, "-ac", "1", "-ar", str(RATE), target],
        check=True,
    )
    refine(target, CLIPS.get(franchise, {}).get(event, {}), scratch)
    print(f"{franchise}/{event}.wav imported")


# ── writing ──────────────────────────────────────────────────────────────────────


def write_wav(path, samples):
    """Writes mono 16 bit samples, scaled so the loudest point sits at PEAK."""
    loudest = max((abs(value) for value in samples), default=1.0) or 1.0
    with wave.open(path, "wb") as out:
        out.setnchannels(1)
        out.setsampwidth(2)
        out.setframerate(RATE)
        frames = b"".join(struct.pack("<h", int(value / loudest * PEAK * 32767)) for value in samples)
        out.writeframes(frames)


# how a recipe is finished unless it asks otherwise: the tail left for its echoes, the loudness it
# is evened out to (None keeps it as built, for short sounds loudnorm cannot measure), a gain in dB
# applied after, and whether the silence at its end is cut
FINISH = {"pad": 0.6, "loudness": -24, "gain": 0, "trim": False}

# what every sound of a franchise is finished with: Elizabeth's are all built here, so none rings
# longer than the moment it belongs to
FRANCHISE_FINISH = {"elizabeth": {"trim": True}}

# trims the silence an echo leaves at the end, read backwards so the start stays untouched
TRIM = "areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.06,areverse"


def ffmpeg(source, target, chain, finish):
    """Runs a file through an ffmpeg filter chain into a mono wav, leaving a tail for the echoes."""
    steps = [f"apad=pad_dur={finish['pad']}", chain]
    if finish["trim"]:
        steps.append(TRIM)
    steps.append("alimiter=limit=0.9")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source,
         "-af", ",".join(steps), "-ac", "1", "-ar", str(RATE), target],
        check=True,
    )


def level(target, scratch, finish):
    """Evens out loudness so a whisper and a fanfare land at the same perceived volume, then
    applies the recipe's gain, quieter for sounds that play on every keypress."""
    filters = []
    if finish["loudness"] is not None:
        filters.append(f"loudnorm=I={finish['loudness']}:TP=-5:LRA=11")
    if finish["gain"]:
        filters.append(f"volume={finish['gain']}dB")
    if not filters:
        return
    leveled = os.path.join(scratch, "leveled.wav")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", target,
         "-af", ",".join(filters), "-ac", "1", "-ar", str(RATE), leveled],
        check=True,
    )
    shutil.move(leveled, target)


def build(franchise, event, recipe, scratch):
    """Builds one event's file. A recipe returns (samples, chain) or (samples, chain, finish)."""
    target = os.path.join(ROOT, franchise, event + ".wav")
    samples, chain, *rest = recipe()
    finish = {**FINISH, **FRANCHISE_FINISH.get(franchise, {}), **(rest[0] if rest else {})}
    dry = os.path.join(scratch, "dry.wav")
    write_wav(dry, samples)
    ffmpeg(dry, target, chain, finish)
    level(target, scratch, finish)


def main():
    """Builds the recipes of the franchises given (all by default), or with --clips finishes the
    clips in CLIPS, or with --import SOURCE FRANCHISE EVENT brings a new clip in."""
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is needed: brew install ffmpeg")
    args = sys.argv[1:]
    with tempfile.TemporaryDirectory() as scratch:
        if args[:1] == ["--clips"]:
            return refine_clips(scratch)
        if args[:1] == ["--import"]:
            if len(args) != 4:
                sys.exit("usage: sounds.py --import SOURCE FRANCHISE EVENT")
            return import_clip(args[1], args[2], args[3], scratch)
        for franchise in args or list(RECIPES):
            os.makedirs(os.path.join(ROOT, franchise), exist_ok=True)
            for event, recipe in RECIPES[franchise].items():
                build(franchise, event, recipe, scratch)
                print(f"{franchise}/{event}.wav ok")


if __name__ == "__main__":
    main()
