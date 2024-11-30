import wave
import serial
import sys

# set according to your system!
# CHANGE ME
SERIAL_PORTNAME = "/dev/ttyUSB1"
BAUD = 115200

# TODO @LAs: this is very approximate, pls help me fix it -kiran

# opens input.wav, sends the data as a set of
def send_wav(filename):
    with wave.open(filename,"rb") as wav_file:
        print(f"This is the sample width:{wav_file.getsampwidth()}")
        assert wav_file.getnchannels() == 1
        assert wav_file.getsampwidth() == 1
        assert wav_file.getframerate() == 8000

        ser = serial.Serial(SERIAL_PORTNAME,BAUD)
        
        print("Sending wav file!")
        nframes = wav_file.getnframes()
        # bytearray i think?
        frames = wav_file.readframes(nframes)
        for i in range(nframes):
            sample = frames[i]
            ser.write( sample.to_bytes(1,'little') )
        print("wav file sent.")
                    
        
        

if __name__ == "__main__":
    if (len(sys.argv)<2):
        print("Usage: python3 send_wav.py <filename>")
        exit()
    filename = sys.argv[1]
    send_wav(filename)
