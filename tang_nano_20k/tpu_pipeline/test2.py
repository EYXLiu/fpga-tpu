import serial
import struct
import time
import numpy as np

PORT = "/dev/cu.usbserial-20250303171"
BAUD = 115200

ser = serial.Serial(PORT, BAUD, timeout=2)


# ============================================================
# Protocol
# ============================================================

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


# ============================================================
# Packing
# ============================================================

def pack_row(row):
    """
    Pack 4 x 8-bit elements into one 32-bit word.

    [A, B, C, D] -> 0xAABBCCDD
    """
    return (
        (int(row[0]) << 24) |
        (int(row[1]) << 16) |
        (int(row[2]) << 8)  |
        int(row[3])
    )


# ============================================================
# Zero-pad a 2x2 matrix into 4x4
# ============================================================

def pad_2x2(matrix):
    """
    Convert:

        [a b]
        [c d]

    into:

        [a b 0 0]
        [c d 0 0]
        [0 0 0 0]
        [0 0 0 0]
    """
    padded = np.zeros((4, 4), dtype=np.int32)
    padded[:2, :2] = matrix
    return padded


# ============================================================
# Single test
# ============================================================

def run_test(test_name, A_2x2, B_2x2):

    print("\n")
    print("=" * 60)
    print(f"TEST: {test_name}")
    print("=" * 60)

    # Expected 2x2 result
    expected_2x2 = A_2x2 @ B_2x2

    # Zero-pad to 4x4
    A = pad_2x2(A_2x2)
    B = pad_2x2(B_2x2)

    # Expected 4x4 result
    expected = A @ B

    print("\nA (4x4 zero-padded):")
    print(A)

    print("\nB (4x4 zero-padded):")
    print(B)

    print("\nExpected 4x4:")
    print(expected)

    # --------------------------------------------------------
    # Clear UART
    # --------------------------------------------------------

    ser.reset_input_buffer()

    # --------------------------------------------------------
    # Write A
    #
    # Addresses 0-3
    # --------------------------------------------------------

    print("\n=== WRITE A ===")

    for i in range(4):

        value = pack_row(A[i])

        print(
            f"A[{i}] = {A[i]} "
            f"-> 0x{value:08X}"
        )

        write_mem(i, value)

    # --------------------------------------------------------
    # Write B
    #
    # Addresses 4-7
    # --------------------------------------------------------

    print("\n=== WRITE B ===")

    for i in range(4):

        value = pack_row(B[i])

        print(
            f"B[{i}] = {B[i]} "
            f"-> 0x{value:08X}"
        )

        write_mem(4 + i, value)

    # --------------------------------------------------------
    # Verify A
    # --------------------------------------------------------

    print("\n=== VERIFY A ===")

    for i in range(4):

        value = read_mem(i)

        expected_value = pack_row(A[i])

        print(
            f"A address {i}: "
            f"0x{value:08X} "
            f"(expected 0x{expected_value:08X})"
        )

        if value != expected_value:
            raise RuntimeError(
                f"A verification failed at address {i}"
            )

    # --------------------------------------------------------
    # Verify B
    # --------------------------------------------------------

    print("\n=== VERIFY B ===")

    for i in range(4):

        addr = 4 + i

        value = read_mem(addr)

        expected_value = pack_row(B[i])

        print(
            f"B address {addr}: "
            f"0x{value:08X} "
            f"(expected 0x{expected_value:08X})"
        )

        if value != expected_value:
            raise RuntimeError(
                f"B verification failed at address {addr}"
            )

    # --------------------------------------------------------
    # Start
    # --------------------------------------------------------

    print("\n=== START MATMUL ===")

    start_matmul()

    # Give FPGA time to finish
    time.sleep(0.1)

    # --------------------------------------------------------
    # Read C
    #
    # C addresses 8-23
    #
    # 8  = C[0][0]
    # 9  = C[0][1]
    # 10 = C[0][2]
    # 11 = C[0][3]
    #
    # 12 = C[1][0]
    # ...
    # --------------------------------------------------------

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

    # --------------------------------------------------------
    # Compare
    # --------------------------------------------------------

    print("\n=== RESULT ===")

    print("\nFPGA C:")
    print(C)

    print("\nExpected C:")
    print(expected)

    if np.array_equal(C, expected):

        print("\n" + "=" * 60)
        print(f"PASS: {test_name}")
        print("=" * 60)

        return True

    else:

        print("\n" + "=" * 60)
        print(f"FAIL: {test_name}")
        print("=" * 60)

        print("\nDifference:")
        print(C - expected)

        return False


# ============================================================
# Test cases
# ============================================================

tests = [

    # --------------------------------------------------------
    # Test 1
    # --------------------------------------------------------

    (
        "Simple",

        np.array([
            [1, 2],
            [3, 4]
        ], dtype=np.int32),

        np.array([
            [5, 6],
            [7, 8]
        ], dtype=np.int32)
    ),

    # --------------------------------------------------------
    # Test 2
    # --------------------------------------------------------

    (
        "Identity",

        np.array([
            [1, 0],
            [0, 1]
        ], dtype=np.int32),

        np.array([
            [10, 20],
            [30, 40]
        ], dtype=np.int32)
    ),

    # --------------------------------------------------------
    # Test 3
    # --------------------------------------------------------

    (
        "Zeros",

        np.array([
            [0, 0],
            [0, 0]
        ], dtype=np.int32),

        np.array([
            [10, 20],
            [30, 40]
        ], dtype=np.int32)
    ),

    # --------------------------------------------------------
    # Test 4
    # --------------------------------------------------------

    (
        "Nontrivial",

        np.array([
            [2, 3],
            [4, 5]
        ], dtype=np.int32),

        np.array([
            [6, 7],
            [8, 9]
        ], dtype=np.int32)
    ),

    # --------------------------------------------------------
    # Test 5
    # --------------------------------------------------------

    (
        "Larger Values",

        np.array([
            [10, 20],
            [30, 40]
        ], dtype=np.int32),

        np.array([
            [50, 60],
            [70, 80]
        ], dtype=np.int32)
    ),
]


# ============================================================
# Run suite
# ============================================================

passed = 0
failed = 0

print("\n")
print("#" * 60)
print("#          ZERO-PADDED 2x2 -> 4x4 FPGA TEST")
print("#" * 60)

for test_name, A, B in tests:

    try:

        if run_test(test_name, A, B):
            passed += 1
        else:
            failed += 1

    except Exception as e:

        print(f"\nERROR in {test_name}: {e}")
        failed += 1

    time.sleep(0.1)


# ============================================================
# Final summary
# ============================================================

print("\n")
print("#" * 60)
print("#                    SUMMARY")
print("#" * 60)

print(f"Passed: {passed}")
print(f"Failed: {failed}")
print(f"Total:  {passed + failed}")

if failed == 0:
    print("\nALL TESTS PASSED")
else:
    print(f"\n{failed} TEST(S) FAILED")


ser.close()