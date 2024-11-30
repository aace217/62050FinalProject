import numpy as np
import wave

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

# Generate 1-second WAV files for each note
for freq, note in fundamental_notes.items():
    t = np.linspace(0, 1, sampleRate, endpoint=False)  # Time array for 1 second
    y = np.sin(2 * np.pi * freq * t)  # Generate sine wave
    y = float2pcm_8bit(y)  # Convert to 8-bit PCM
    
    # Write the WAV file using the wave module
    with wave.open(f'{note}.wav', 'wb') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(1)  # Sample width = 1 byte (8-bit)
        wav_file.setframerate(sampleRate)  # Set frame rate
        wav_file.writeframes(y.tobytes())  # Write PCM data
    print(f"Just made the file: {note}.wav")
