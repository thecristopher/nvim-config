#!/usr/bin/env python3
"""Builds the synthesized franchise sounds into sounds/<franchise>/<event>.wav.

Tones and noise are synthesized here and ffmpeg adds the room (echo, filters). The clips from the
games live next to them and are left alone. Only the standard library is needed, plus ffmpeg.

Usage:
    python3 scripts/sounds.py                 # every franchise
    python3 scripts/sounds.py resident_evil   # just one
"""

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


RECIPES = {
    # title, door, rest (the save room), continue, grace (the typewriter saving), died (game over), merchant,
    # bought, welcome, weapon, summon, comfort, expedition and the hud_ inventory sounds are clips from the game, so they are not built here
    "resident_evil": {
        "boss": re_boss, "felled": re_felled, "great": re_great, "cleansed": re_cleansed,
        "region": re_region,
    },
    # title, died, felled, grace, rest, zone, merchant, phantom and continue are clips from the game, so they are not built here
    "elden_ring": {
        "great": er_great, "cleansed": er_cleansed,
        "fog": er_fog, "boss": er_boss, "region": er_region,
    },
}


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


def ffmpeg(source, target, chain):
    """Runs a file through an ffmpeg filter chain into a mono wav, leaving a tail for the echoes."""
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source,
         "-af", f"apad=pad_dur=0.6,{chain},alimiter=limit=0.9", "-ac", "1", "-ar", str(RATE), target],
        check=True,
    )


def level(target, scratch):
    """Evens out loudness so a whisper and a fanfare land at the same perceived volume."""
    leveled = os.path.join(scratch, "leveled.wav")
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", target,
         "-af", "loudnorm=I=-24:TP=-5:LRA=11", "-ac", "1", "-ar", str(RATE), leveled],
        check=True,
    )
    shutil.move(leveled, target)


def build(franchise, event, recipe, scratch):
    """Builds one event's file."""
    target = os.path.join(ROOT, franchise, event + ".wav")
    samples, chain = recipe()
    dry = os.path.join(scratch, "dry.wav")
    write_wav(dry, samples)
    ffmpeg(dry, target, chain)
    level(target, scratch)


def main():
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is needed: brew install ffmpeg")
    wanted = sys.argv[1:] or list(RECIPES)
    with tempfile.TemporaryDirectory() as scratch:
        for franchise in wanted:
            os.makedirs(os.path.join(ROOT, franchise), exist_ok=True)
            for event, recipe in RECIPES[franchise].items():
                build(franchise, event, recipe, scratch)
                print(f"{franchise}/{event}.wav ok")


if __name__ == "__main__":
    main()
