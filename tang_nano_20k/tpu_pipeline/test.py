import serial
import struct
import time
import numpy as np

PORT = "/dev/cu.usbserial-20250303171"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=2)

# ------------------------------------------------------------
# Matrices
# ------------------------------------------------------------

A = np.array([
    [1,  2,  3,  4],
    [5,  6,  7,  8],
    [9, 10, 11, 12],
    [13, 14, 15, 16]
], dtype=np.int32)

B = np.array([
    [17, 18,19, 20],
    [21, 22, 23, 24],
    [25, 26, 27, 28],
    [29, 30, 31, 32]
], dtype=np.int32)

expected = A @ B


# ------------------------------------------------------------
# Protocol
# ------------------------------------------------------------

def write_mem(addr, value):
    """
    W + 16-bit big-endian address + 32-bit big-endian data
    FPGA responds with 0x06 ACK.
    """

    packet = b"W" + struct.pack(">H", addr) + struct.pack(">I", value)

    print(f"TX: {packet.hex(' ')}")

    ser.write(packet)

    ack = ser.read(1)

    print(f"RX: {ack.hex(' ')}")

    if ack != b"\x06":
        raise RuntimeError(
            f"Write failed at address {addr}: "
            f"expected ACK 06, got {ack.hex(' ')}"
        )


def read_mem(addr):
    """
    R + 16-bit big-endian address
    FPGA responds with 32-bit big-endian data.
    """

    packet = b"R" + struct.pack(">H", addr)

    print(f"TX: {packet.hex(' ')}")

    ser.write(packet)

    data = ser.read(4)

    print(f"RX: {data.hex(' ')}")

    if len(data) != 4:
        raise RuntimeError(
            f"Read failed at address {addr}: "
            f"expected 4 bytes, got {len(data)}"
        )

    return struct.unpack(">I", data)[0]


def start_matmul():
    """
    Send S command.
    """

    packet = b"S"

    print(f"TX: {packet.hex(' ')}")

    ser.write(packet)


# ------------------------------------------------------------
# Pack matrix rows into 32-bit words
# ------------------------------------------------------------

def pack_row(row):
    """
    [A, B, C, D] -> 0xAABBCCDD
    """

    return (
        (int(row[0]) << 24) |
        (int(row[1]) << 16) |
        (int(row[2]) << 8)  |
        int(row[3])
    )


# ------------------------------------------------------------
# Clear any old UART data
# ------------------------------------------------------------

ser.reset_input_buffer()


# ------------------------------------------------------------
# Write A
# Addresses 0-3
# ------------------------------------------------------------

print("\n=== WRITE A ===")

for i in range(4):
    value = pack_row(A[i])

    print(f"A[{i}] = {A[i]} -> 0x{value:08X}")

    write_mem(i, value)


# ------------------------------------------------------------
# Write B
# Addresses 4-7
# ------------------------------------------------------------

print("\n=== WRITE B ===")

for i in range(4):
    value = pack_row(B[i])

    print(f"B[{i}] = {B[i]} -> 0x{value:08X}")

    write_mem(4 + i, value)


# ------------------------------------------------------------
# Optional: verify A/B were written correctly
# ------------------------------------------------------------

print("\n=== VERIFY INPUTS ===")

for i in range(4):
    value = read_mem(i)

    expected_value = pack_row(A[i])

    print(
        f"A address {i}: "
        f"0x{value:08X} "
        f"(expected 0x{expected_value:08X})"
    )

    assert value == expected_value


for i in range(4):
    value = read_mem(4 + i)

    expected_value = pack_row(B[i])

    print(
        f"B address {4+i}: "
        f"0x{value:08X} "
        f"(expected 0x{expected_value:08X})"
    )

    assert value == expected_value

# ------------------------------------------------------------
# Start matrix multiplication
# ------------------------------------------------------------

print("\n=== START MATMUL ===")

start_matmul()

# Give FPGA time to:
#   read A
#   read B
#   run systolic array
#   store C
#
# This is deliberately generous for the first test.

time.sleep(0.1)


# ------------------------------------------------------------
# Read C
# Addresses 8-23
# ------------------------------------------------------------

print("\n=== READ C ===")

C = np.zeros((4, 4), dtype=np.int32)

for i in range(4):
    for j in range(4):

        addr = 8 + i * 4 + j

        value = read_mem(addr)

        C[i][j] = value

        print(
            f"C[{i}][{j}] "
            f"(addr {addr}) = {value}"
        )


# ------------------------------------------------------------
# Results
# ------------------------------------------------------------

print("\n=== RESULTS ===")

print("\nA:")
print(A)

print("\nB:")
print(B)

print("\nFPGA C:")
print(C)

print("\nExpected C:")
print(expected)


# ------------------------------------------------------------
# Compare
# ------------------------------------------------------------

if np.array_equal(C, expected):

    print("\n================================")
    print("       MATMUL TEST PASSED")
    print("================================")

else:

    print("\n================================")
    print("       MATMUL TEST FAILED")
    print("================================")

    print("\nDifference:")
    print(C - expected)

    raise RuntimeError("FPGA result does not match expected result")


ser.close()