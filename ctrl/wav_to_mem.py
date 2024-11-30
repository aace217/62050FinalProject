import sys
import wave

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {0} <wav file to convert>".format(sys.argv[0]))
    else:
        input_fname = sys.argv[1]
        
        try:
            # Open the WAV file
            with wave.open(input_fname, 'rb') as wav_file:
                # Ensure it is 8-bit audio
                n_channels = wav_file.getnchannels()
                sampwidth = wav_file.getsampwidth()
                framerate = wav_file.getframerate()
                n_frames = wav_file.getnframes()
                audio_data = wav_file.readframes(n_frames)
                
                if sampwidth != 1:
                    print(f"Error: {input_fname} is not an 8-bit WAV file (sample width: {sampwidth} bytes).")
                    sys.exit(1)
                
                print(f"Processing {input_fname}:")
                print(f"  Channels: {n_channels}")
                print(f"  Sample Width: {sampwidth} bytes (8-bit)")
                print(f"  Frame Rate: {framerate} Hz")
                print(f"  Total Frames: {n_frames}")
                
                # Convert audio data to hex format
                with open('audio_data.mem', 'w') as f:
                    f.write('\n'.join([f'{sample:02x}' for sample in audio_data]))
                
                print(f"Audio data saved to audio_data.mem")
        
        except wave.Error as e:
            print(f"Error processing {input_fname}: {e}")
