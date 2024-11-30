import serial
import csv


# opens serial port, waits for 6 seconds of 8kHz audio data, writes it to output.wav

# set to proper serial port name and WAV!
# find the port name using test_ports.py
# CHANGE ME
SERIAL_PORT_NAME = "/dev/cu.usbserial-88742923009B1"
BAUD_RATE = 230400

# 100 cycles to get a new data point with baud rate of 200MHz means 2MHz samples per second
# 200,000,000 cycles/sec * 1 bit/100 cycles = 2,000,000 bit/sec

ser = serial.Serial(SERIAL_PORT_NAME)
ser.baudrate = BAUD_RATE
print("Serial port initialized")

print("Recording 6 seconds of audio:")
beatPoints = []
yPoints = []
batonPoints = []
for i in range(20000):
    y_com = int.from_bytes(ser.read(), 'little')
    beat_detected = int.from_bytes(ser.read(), 'little')
    # print(y_com, beat_detected)

    
    
    # to_add = [0,0]
    # for j in range(2):
    # received_byte = int.from_bytes(ser.read(), 'little')
        # to_add[j] = received_byte
        # beat_detected = int.from_bytes(ser.read(), 'little')
    
    # beat_detected = (0b10000000 & int.from_bytes(received_byte,'little')) >> 7
    # if beat_detected != 0:
    #     print(beat_detected)
    # y_com = (0b01111111 & int.from_bytes(received_byte,'little')) << 1
    # if ((i+1)%8000==0):
    #     print(f"{(i+1)/8000} seconds complete")
    # if i % 4 == 2 or i % 3 == 3:
    #     beatPoints.append(received_byte)
    # elif i % 4 == 0 or i % 4 == 1:
    #     yPoints.append(received_byte)
    batonPoints.append([y_com, beat_detected])


print(batonPoints)

with open('baton_pts.csv','w', newline='') as file:
    writer = csv.writer(file)

    for i in range(len(batonPoints)):
        # writer.writerow([i, beatPoints[i], yPoints[i]])
        writer.writerow([i, batonPoints[i][0], batonPoints[i][1]])
        # writer.writerow([i, batonPoints[i][0]])



