import serial
import time
import sys

PORT = "COM5"
BAUD = 115200
TIMEOUT = 1

# Opcodes
READ_FULL_WORD = 0x01
READ_LOW_NIBBLE = 0x02
READ_HIGH_NIBBLE = 0x03
WRITE_FULL_WORD = 0x04
WRITE_LOW_NIBBLE = 0x05
WRITE_HIGH_NIBBLE = 0x06


def main():
    print("PC Application")
    print("Commands:")
    print("READ FULL WORD <addr>")
    print("READ LOW NIBBLE <addr>")
    print("READ HIGH NIBBLE <addr>")
    print("WRITE FULL WORD <addr> <data>")
    print("WRITE LOW NIBBLE <addr> <data>")
    print("WRITE HIGH NIBBLE <addr> <data>")

    # Establish serial communication
    try:
        ser = serial.Serial(PORT, BAUD, timeout=TIMEOUT)
        print(f"Connected to {PORT} at {BAUD} baud.")
        print()
    except Exception as e:
        print(f"Failed to connect to {PORT}: {e}")
        return

    while True:
        # Prompt user for command
        user_in = input(">").strip()
        if not user_in:
            continue
        if user_in.lower() == 'exit' or user_in.lower() == 'quit' or user_in.lower() == 'q':
            break

        # Store user input as array
        split_user_input = user_in.split()

        command1 = split_user_input[0].upper() # READ/WRITE
        command2 = split_user_input[1].upper() # FULL/LOW/HIGH
        command3 = split_user_input[2].upper() # WORD/NIBBLE

        # Get address
        address = int(split_user_input[3])
        if not (0 <= address <= 255): # address can only be a maximum of 8 bits (3 row, 3 col, 2 bank)
            print("Invalid address")
            continue

        # Get data
        data = 0
        if command1 == "WRITE":
            # Only get data from user if write command is used
            data = int(split_user_input[4])
            if not (0 <= data <= 255): # data can only be 8 bits wide (we only using 8 bit chips)
                print("Invalid data")
                continue

        # Determine opcode
        opcode = 0
        is_read = False
        is_nibble = False

        if command1 == "READ" and command2 == "FULL" and command3 == "WORD":
            opcode = READ_FULL_WORD
            is_read = True
        elif command1 == "READ" and command2 == "LOW" and command3 == "NIBBLE":
            opcode = READ_LOW_NIBBLE
            is_read = True
            is_nibble = True
        elif command1 == "READ" and command2 == "HIGH" and command3 == "NIBBLE":
            opcode = READ_HIGH_NIBBLE
            is_read = True
            is_nibble = True
        elif command1 == "WRITE" and command2 == "FULL" and command3 == "WORD":
            opcode = WRITE_FULL_WORD
        elif command1 == "WRITE" and command2 == "LOW" and command3 == "NIBBLE":
            opcode = WRITE_LOW_NIBBLE
        elif command1 == "WRITE" and command2 == "HIGH" and command3 == "NIBBLE":
            opcode = WRITE_HIGH_NIBBLE
        else:
            print("Invalid command")
            continue

        # Always transmit 3 bytes to work with simplified state machine
        transmit = bytearray([opcode, address, data])
        ser.reset_input_buffer()
        ser.reset_output_buffer()
        ser.write(transmit)

        # Receive from fpga if read command was entered
        if is_read:
            receive = ser.read(1)
            if receive:
                received_data = receive[0]
                if is_nibble:
                    # Only display the nibble instead of a full 8 bits
                    received_data = received_data & 0x0F
                    print(f"DATA = {received_data} / {received_data:04b}")
                else:
                    high_nibble = (received_data >> 4) & 0x0F
                    low_nibble = received_data & 0x0F
                    print(f"DATA = {received_data} / {high_nibble:04b}_{low_nibble:04b}")
            else:
                print("Receive failed")
        print()

    ser.close()
    print("Disconnected")


if __name__ == '__main__':
    main()