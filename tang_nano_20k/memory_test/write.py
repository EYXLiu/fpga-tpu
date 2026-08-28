import serial
import time

PORT = "/dev/cu.usbserial-20250303171"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=1)

time.sleep(1)

print("Sending A")

ser.write(b"A")
ser.flush()

reponse = ""
response = ser.read(1)

print("Received:", response)
print("As text:", response.decode())

ser.close()

print("Done")