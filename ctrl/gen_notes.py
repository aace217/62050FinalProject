import numpy as np
from scipy.io import wavfile

# Define the sample rate (frame rate) and fundamental notes
sampleRate = 8000  # Set frame rate to 8000 Hz
fundamental_notes = {
    440: "A", 466.16: "A#", 493.88: "B", 261.63: "C", 277.18: "C#",
    293.66: "D", 311.13: "D#", 329.63: "E", 349.23: "F", 369.99: "F#",
    392: "G", 415.3: "G#"
}

# Function to convert float signal to 8-bit PCM format
def float2pcm_8bit(sig):
    sig = np.asarray(sig)  # Ensure signal is a NumPy array
    return ((sig + 1.0) * 127.5).clip(0, 255).astype(np.uint8)  # Map to [0, 255]

# Generate WAV files for each note
for note in fundamental_notes.keys():
    t = np.linspace(0, 5, sampleRate * 5, endpoint=False)  # Adjust time array for 8000 Hz
    y = np.sin(2 * np.pi * note * t)  # Generate sine wave
    y = float2pcm_8bit(y)  # Convert to 8-bit PCM
    wavfile.write(f'{fundamental_notes[note]}.wav', sampleRate, y)  # Save WAV file
    print(f"Just made the file: {fundamental_notes[note]}.wav")
