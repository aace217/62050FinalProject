import serial
import csv


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME
SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009B1"
BAUD_RATE = 115200

# 100 cycles to get a new data point with baud rate of 200MHz means 2MHz samples per second
# 200,000,000 cycles/sec * 1 bit/100 cycles = 2,000,000 bit/sec

ser = serial.Serial(SERIAL_PORT_NAME)
ser.baudrate = BAUD_RATE
print("Serial port initialized")

print("Recording 6 seconds of audio:")
batonPoints = []
for i in range(115200*1):
    received_byte = ser.read()
    beat_detected = (0b10000000 & int.from_bytes(received_byte,'little')) >> 7
    y_com = (0b01111111 & int.from_bytes(received_byte,'little'))
    if ((i+1)%115200==0):
        print(f"{(i+1)/115200} seconds complete")
    batonPoints.append((beat_detected,y_com))


with open('baton_pts.csv','w', newline='') as file:
    writer = csv.writer(file)

    for i in range(len(batonPoints)):
        writer.writerow([i, batonPoints[i][0], batonPoints[i][1]])



