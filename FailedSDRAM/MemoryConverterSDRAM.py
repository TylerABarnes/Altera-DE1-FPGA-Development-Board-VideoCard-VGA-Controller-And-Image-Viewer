import os

def read_binary_file(file_path):
    with open(file_path, 'rb') as file:
        return file.read()

def convert_to_16bit_rows(binary_data):
    bit_string = ''.join(f'{byte:08b}' for byte in binary_data)
    rows = [bit_string[i:i+16] for i in range(0, len(bit_string), 16)]
    return rows

def save_to_text_file(rows, output_path):
    with open(output_path, 'w') as file:
        for row in rows:
            file.write(row + '\n')

def main():
    desktop_path = os.path.join(os.path.expanduser("~"), 'Desktop')
    binary_file_path = os.path.join(desktop_path, 'EntireTestRaw.bin')
    output_file_path = os.path.join(desktop_path, 'EntireMemoryTestReadable.txt')

    # Read the binary file
    binary_data = read_binary_file(binary_file_path)

    # Convert binary data to 16-bit rows
    rows = convert_to_16bit_rows(binary_data)

    # Save the rows to a text file
    save_to_text_file(rows, output_file_path)

    print(f"Conversion complete. Output saved to {output_file_path}")

if __name__ == "__main__":
    main()
