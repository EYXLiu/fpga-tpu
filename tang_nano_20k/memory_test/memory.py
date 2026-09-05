import struct
import serial

PORT = "/dev/cu.usbserial-20250303171"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=3)

def read(addr):
    packet = b'R' + struct.pack(">H", addr)

    print(f"TX: {packet.hex(' ')}")

    ser.write(packet)

    data = ser.read(4)

    print(f"RX: {data.hex(' ')}")

    if len(data) != 4:
        print(f"Expected 4 bytes, got {len(data)}")
        return

    return struct.unpack(">I", data)[0]

def write(addr, data):
    packet = b'W' + struct.pack(">H", addr) + struct.pack(">I", data)

    print(f"TX: {packet.hex(' ')}")

    ser.write(packet)

    ack = ser.read(1)

    print(f"RX: {ack.hex(' ')}")

    if ack != b'\x06':
        raise RuntimeError("Write failed")

write(0, 123)
write(1, 234)
write(2, 345)

print(read(0))
print(read(1))
print(read(2))