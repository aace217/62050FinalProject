import numpy as np
from scipy.io import wavfile

sampleRate = 44100
fundamental_notes = {440: "A", 466.16: "A#", 493.88: "B", 261.63: "C", 277.18: "C#", 
                     293.66: "D", 311.13: "D#", 329.63: "E", 349.23: "F", 369.99: "F#", 
                     392: "G", 415.3: "G#"}

def float2pcm(sig, dtype='int16'): 
    sig = np.asarray(sig) 
    dtype = np.dtype(dtype)
    i = np.iinfo(dtype)
    abs_max = 2 ** (i.bits - 1)
    offset = i.min + abs_max
    return (sig * abs_max + offset).clip(i.min, i.max).astype(dtype)

for note in fundamental_notes.keys():
    t = np.linspace(0, 5, sampleRate * 5, endpoint=False)  #  Produces a 5-second Audio-File
    y = np.sin(2 * np.pi * note * t)  # Corrected frequency generation
    y = float2pcm(y)
    wavfile.write(f'{fundamental_notes[note]}.wav', sampleRate, y)
    print(f"Just made the file: {fundamental_notes[note]}.wav")
