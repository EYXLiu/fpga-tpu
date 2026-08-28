import serial

PORT = "/dev/cu.usbserial-20250303171"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=1)

while True:
    data = ser.read(1)

    if data:
        print(data.hex(), data)