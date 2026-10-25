#!/usr/bin/env python3
"""Builds every franchise sound from scratch into sounds/<franchise>/<event>.wav.

Nothing is sampled from the games: tones and noise are synthesized here, voices come from Piper
(a local neural TTS) or macOS `say` as a fallback, and ffmpeg adds the room (echo, filters, pitch).
Only the standard library is needed, plus ffmpeg.

Usage:
    python3 scripts/sounds.py --setup-voices  # once: Piper and its voices, for natural speech
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
# Each returns (samples, ffmpeg filter), or ("say", voice, text, ffmpeg filter) for a spoken line.

# a big hall: three echoes, each further and fainter
HALL = "aecho=0.8:0.8:90|240|520:0.45|0.3|0.18"
ROOM = "aecho=0.8:0.6:40|110:0.35|0.18"


def deep_voice(pitch):
    """ffmpeg chain that lowers a voice a touch without slowing it, and trims rumble and hiss.

    Voices arrive at 22050 Hz, so they are brought to RATE first: asetrate relabels the rate it is
    given, and relabeling 22050 Hz audio as 44100 Hz would push the voice up an octave instead.
    """
    return f"aresample={RATE},asetrate={RATE}*{pitch},aresample={RATE},atempo={1 / pitch:.4f},highpass=f=70,lowpass=f=9000"


# Spoken lines: (role, text, length_scale, ffmpeg chain). length_scale above 1 speaks slower.
def re_title():
    return ("voice", "announcer", "Resident Evil.", 1.35, f"{deep_voice(0.8)},{HALL}")


def re_died():
    return ("voice", "announcer", "You are dead.", 1.4, f"{deep_voice(0.78)},{HALL}")


def re_merchant():
    return ("voice", "merchant", "What are ya buyin'?", 1.35, f"{deep_voice(0.94)},{ROOM}")


def hinge_squeal(seconds, seed=3):
    """A hinge rubbing: stick and slip at a few hundred times a second, so it squeals with a pitch.

    The pitch rises while the door swings and sags at the end, every cycle a little off from the last,
    and the hinge catches now and then, which is what makes it sound old.
    """
    rng = random.Random(seed)
    count = int(seconds * RATE)
    out, phase, freq, grip = [], 0.0, 150.0, 1.0
    for index in range(count):
        progress = index / count
        target = 150 + 260 * math.sin(math.pi * min(1.0, progress * 1.3)) ** 0.7
        phase += freq / RATE
        if phase >= 1.0:
            # a new slip: the pitch jitters and the grip sometimes catches
            phase -= 1.0
            freq = target * rng.uniform(0.94, 1.06)
            grip = 0.25 if rng.random() < 0.06 else min(1.0, grip + 0.25)
        out.append(((1.0 - phase) ** 4 - 0.2) * grip)
    return out


def latch():
    """The handle turning: two small metallic clicks."""
    tick = decay(highpass(noise(0.03, seed=8), 2500), 0.004)
    ring = decay(tone(3150, 0.12), 0.03)
    click = mix((tick, 1.0, 0.0), (ring, 0.25, 0.0))
    return mix((click, 0.8, 0.0), (click, 0.6, 0.085))


def slam():
    """The door landing in its frame: a low body, a wooden knock and a small rattle after."""
    body = decay(tone(110, 0.5, glide_to=80), 0.12)
    knock = decay(lowpass(highpass(noise(0.25, seed=19), 180), 1300), 0.05)
    rattle = decay(lowpass(highpass(noise(0.12, seed=23), 400), 2200), 0.02)
    return mix((thump(62, 0.7), 0.9, 0.0), (body, 0.7, 0.0), (knock, 0.9, 0.0), (rattle, 0.4, 0.07))


def re_door():
    # the handle, the long squeal of the hinge with air pushed by the swing, and the frame
    squeal = envelope(lowpass(highpass(hinge_squeal(1.45), 300), 2600), attack=0.12, release=0.3)
    air = envelope(lowpass(noise(1.3, seed=29), 500), attack=0.5, release=0.5)
    return mix(
        (latch(), 0.7, 0.0),
        (squeal, 0.75, 0.2),
        (air, 0.25, 0.3),
        (slam(), 1.0, 1.75),
    ), f"lowpass=f=2800,lowpass=f=2800,{ROOM}"


def re_typewriter():
    # keys struck at an uneven pace, then the carriage bell asks the question
    rng = random.Random(11)
    layers, at = [], 0.0
    for _ in range(9):
        key = decay(highpass(noise(0.05, seed=rng.randint(1, 99)), 1800), 0.012)
        layers.append((key, 0.9, at))
        at += rng.uniform(0.08, 0.17)
    layers.append((bell(1760, 1.2), 0.45, at + 0.15))
    return mix(*layers), f"lowpass=f=7000,{ROOM}"


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


def re_grace():
    # the safe room: a calm major seventh breathing in, nothing chasing you here
    pad = lowpass(chord([261.63, 329.63, 392.0, 493.88], 2.6, "triangle", detune=0.003), 1600)
    return envelope(pad, attack=0.7, release=1.2), HALL


def re_cleansed():
    # containment: a filter sweep falling away, then a clean confirm chime
    sweep = envelope(lowpass(noise(1.0, seed=21), lambda index: 3000 * math.exp(-index / 12000.0) + 120), 0.02, 0.4)
    return mix((sweep, 0.7, 0.0), (bell(1568, 1.0), 0.45, 0.55)), ROOM


def re_rest():
    return re_typewriter()


def re_region():
    # a new location: a low swell and the click of the map
    swell = envelope(lowpass(chord([55.0, 82.41], 1.5, "saw"), 260), attack=0.6, release=0.6)
    click = decay(highpass(noise(0.05, seed=5), 2000), 0.01)
    return mix((swell, 0.9, 0.0), (click, 0.6, 1.2)), ROOM


def er_title():
    # the narrator speaks the name softly into a vast hall, a low choir rising under it
    return ("voice", "narrator", "Elden Ring.", 1.5, f"{deep_voice(0.86)},volume=0.8,{HALL},{HALL}")


def er_choir_pad(freqs, seconds, brightness):
    """Detuned saws through a slowly opening filter, the closest thing to a choir from scratch."""
    pad = chord(freqs, seconds, "saw", detune=0.006)
    count = len(pad)
    return lowpass(pad, lambda index: 250 + brightness * index / count)


def er_died():
    drone = envelope(er_choir_pad([55.0, 82.41, 110.0], 3.2, 500), attack=0.4, release=1.6)
    return mix((drone, 0.8, 0.0), (bell(196, 3.0), 0.55, 0.05)), HALL


def er_felled():
    swell = envelope(er_choir_pad([146.83, 220.0, 293.66, 369.99], 2.2, 2600), attack=0.5, release=0.9)
    return swell, HALL


def er_great():
    swell = envelope(er_choir_pad([98.0, 146.83, 196.0, 246.94, 293.66], 3.0, 3200), attack=0.7, release=1.2)
    timpani = thump(65, 1.0)
    return mix((timpani, 0.9, 0.0), (swell, 0.9, 0.1), (timpani, 0.6, 0.45)), HALL


def er_grace():
    # golden motes: bell tones from a pentatonic scale over a soft bed
    rng = random.Random(9)
    scale = [783.99, 880.0, 1046.5, 1174.66, 1318.51, 1567.98]
    layers = [(bell(rng.choice(scale), 1.4), 0.22, index * 0.17) for index in range(9)]
    bed = envelope(lowpass(chord([261.63, 392.0], 2.6, "triangle"), 900), 0.6, 1.0)
    layers.append((bed, 0.5, 0.0))
    return mix(*layers), HALL


def er_cleansed():
    whoosh = envelope(lowpass(noise(1.2, seed=31), lambda index: 300 + 4000 * index / (1.2 * RATE)), 0.5, 0.4)
    return mix((whoosh, 0.6, 0.0), (bell(1046.5, 1.4), 0.4, 0.8)), HALL


def er_fog():
    # wind through the fog wall, rising and passing
    wind = lowpass(noise(1.5, seed=13), lambda index: 500 + 700 * math.sin(math.pi * index / (1.5 * RATE)))
    return envelope(wind, attack=0.5, release=0.7), ROOM


def er_rest():
    # sitting at the grace: a warm low bed and the crackle of embers
    bed = envelope(lowpass(chord([130.81, 196.0], 2.8, "triangle"), 700), 0.8, 1.2)
    rng = random.Random(17)
    crackles = [(decay(highpass(noise(0.03, seed=rng.randint(1, 500)), 2500), 0.006), 0.35, rng.uniform(0.2, 2.5)) for _ in range(14)]
    return mix((bed, 0.7, 0.0), *crackles), ROOM


def er_boss():
    drums = [(thump(55, 0.5), 0.9, at) for at in (0.0, 0.4, 0.8, 1.0, 1.2)]
    strings = [value * (0.6 + 0.4 * math.sin(index / 400.0)) for index, value in enumerate(er_choir_pad([73.42, 110.0, 146.83], 1.9, 1400))]
    return mix((envelope(strings, 0.6, 0.4), 0.7, 0.0), *drums), HALL


def er_region():
    gong = bell(110, 2.4)
    pad = envelope(er_choir_pad([220.0, 329.63], 2.2, 1200), attack=0.6, release=0.9)
    return mix((gong, 0.6, 0.0), (pad, 0.6, 0.15)), HALL


RECIPES = {
    "resident_evil": {
        "title": re_title, "died": re_died, "merchant": re_merchant, "door": re_door,
        "rest": re_rest, "boss": re_boss, "felled": re_felled, "great": re_great,
        "grace": re_grace, "cleansed": re_cleansed, "region": re_region,
    },
    "elden_ring": {
        "title": er_title, "died": er_died, "felled": er_felled, "great": er_great,
        "grace": er_grace, "cleansed": er_cleansed, "fog": er_fog, "rest": er_rest,
        "boss": er_boss, "region": er_region,
    },
}

# the Elden Ring title is a whisper over the choir, so its pad is laid under the voice afterwards
def re_impact():
    """The hit and low rumble under the announcer, the way the old title screens open."""
    rumble = envelope(lowpass(chord([41.2, 55.0], 2.4, "saw"), 180), attack=0.02, release=1.4)
    return mix((thump(45, 1.2), 1.0, 0.0), (rumble, 0.6, 0.0))


# spoken lines get a bed laid under them afterwards
UNDERLAYS = {
    ("elden_ring", "title"): lambda: envelope(er_choir_pad([65.41, 98.0, 130.81], 3.2, 900), 0.8, 1.4),
    ("resident_evil", "title"): re_impact,
    ("resident_evil", "died"): re_impact,
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


def read_wav(path):
    """Reads mono 16 bit samples back as floats."""
    with wave.open(path, "rb") as source:
        data = source.readframes(source.getnframes())
    return [value / 32767 for (value,) in struct.iter_unpack("<h", data)]


def ffmpeg(source, target, chain):
    """Runs a file through an ffmpeg filter chain into a mono wav, leaving a tail for the echoes."""
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", "-i", source,
         "-af", f"apad=pad_dur=0.6,{chain},alimiter=limit=0.9", "-ac", "1", "-ar", str(RATE), target],
        check=True,
    )


# Piper speaks the lines when it is set up (python3 scripts/sounds.py --setup-voices), macOS say otherwise.
# The path stays short on purpose: espeak, inside Piper, gives up on long data paths.
PIPER_HOME = os.environ.get("ELDENTREE_PIPER_HOME", os.path.expanduser("~/.local/share/eldentree"))
VOICE_URL = "https://huggingface.co/rhasspy/piper-voices/resolve/main/en/"

# role: (piper model, where it lives in the voices repo, say voice to fall back on)
VOICES = {
    "announcer": ("en_US-ryan-high", "en_US/ryan/high", "Ralph"),
    "merchant": ("en_GB-northern_english_male-medium", "en_GB/northern_english_male/medium", "Daniel"),
    "narrator": ("en_GB-northern_english_male-medium", "en_GB/northern_english_male/medium", "Whisper"),
}


def piper_python():
    """Returns Piper's python when it is installed, None otherwise."""
    python = os.path.join(PIPER_HOME, "piper", "bin", "python")
    return python if os.path.exists(python) else None


def piper_model(role):
    """Returns the downloaded model for a role, None when it is missing."""
    model = os.path.join(PIPER_HOME, "voices", VOICES[role][0] + ".onnx")
    return model if os.path.exists(model) else None


def setup_voices():
    """Installs Piper in its own venv and downloads every voice the recipes use."""
    venv = os.path.join(PIPER_HOME, "piper")
    if not piper_python():
        subprocess.run([sys.executable, "-m", "venv", venv], check=True)
        subprocess.run([os.path.join(venv, "bin", "pip"), "install", "-q", "piper-tts"], check=True)
    os.makedirs(os.path.join(PIPER_HOME, "voices"), exist_ok=True)
    for name, path, _ in set(VOICES.values()):
        for suffix in (".onnx", ".onnx.json"):
            target = os.path.join(PIPER_HOME, "voices", name + suffix)
            if not os.path.exists(target):
                # curl uses the system's certificates, which some networks need
                subprocess.run(["curl", "-sSfL", "-o", target, VOICE_URL + path + "/" + name + suffix], check=True)
        print(f"voice {name} ready")


def speak(role, text, length, target, chain, scratch):
    """Speaks a line with Piper, or macOS say when Piper is not set up, then shapes it with ffmpeg.

    Returns False when neither can speak.
    """
    raw = os.path.join(scratch, "voice.wav")
    if piper_python() and piper_model(role):
        subprocess.run(
            [piper_python(), "-m", "piper", "-m", piper_model(role), "-f", raw, "--length-scale", str(length)],
            input=text, text=True, check=True, capture_output=True,
        )
    elif shutil.which("say"):
        raw = os.path.join(scratch, "voice.aiff")
        subprocess.run(["say", "-v", VOICES[role][2], "-r", str(int(170 / length)), "-o", raw, text], check=True)
    else:
        return False
    ffmpeg(raw, target, chain)
    return True


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
    """Builds one event's file, returns False when a tool it needs is missing."""
    target = os.path.join(ROOT, franchise, event + ".wav")
    made = recipe()
    if made[0] == "voice":
        if not speak(made[1], made[2], made[3], target, made[4], scratch):
            return False
    else:
        dry = os.path.join(scratch, "dry.wav")
        write_wav(dry, made[0])
        ffmpeg(dry, target, made[1])
    underlay = UNDERLAYS.get((franchise, event))
    if underlay:
        write_wav(target, mix((underlay(), 0.5, 0.0), (read_wav(target), 1.0, 0.25)))
    level(target, scratch)
    return True


def main():
    if not shutil.which("ffmpeg"):
        sys.exit("ffmpeg is needed: brew install ffmpeg")
    if "--setup-voices" in sys.argv:
        return setup_voices()
    print("voices: " + ("piper" if piper_python() else "macOS say, run --setup-voices for natural ones"))
    wanted = sys.argv[1:] or list(RECIPES)
    with tempfile.TemporaryDirectory() as scratch:
        for franchise in wanted:
            os.makedirs(os.path.join(ROOT, franchise), exist_ok=True)
            for event, recipe in RECIPES[franchise].items():
                status = "ok" if build(franchise, event, recipe, scratch) else "skipped, nothing can speak"
                print(f"{franchise}/{event}.wav {status}")


if __name__ == "__main__":
    main()
