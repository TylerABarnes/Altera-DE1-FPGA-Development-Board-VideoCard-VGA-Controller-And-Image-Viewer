import os
from PIL import Image

def convert_image_to_raw(image_path):
    # Open the image
    img = Image.open(image_path)

    # Ensure the image is in RGBA mode
    img = img.convert('RGBA')

    # Resize the image to 640x480 using LANCZOS resampling
    img = img.resize((640, 480), resample=Image.LANCZOS)

    # Get the pixel data
    pixels = list(img.getdata())

    # List to store raw binary values
    raw_binary = bytearray()  # Using bytearray to store binary data efficiently

    for pixel in pixels:
        # Extract RGB values and reduce to 3-3-2 bits
        red = (pixel[0] >> 5) & 0x07  # 3 bits for red
        green = (pixel[1] >> 5) & 0x07  # 3 bits for green
        blue = (pixel[2] >> 6) & 0x03  # 2 bits for blue

        # Combine into a single 8-bit value
        raw_value = (red << 5) | (green << 2) | blue

        # Append the raw value to the list
        raw_binary.append(raw_value)

    return raw_binary

# Get the path to the user's desktop
desktop_path = os.path.join(os.path.join(os.environ['USERPROFILE']), 'Desktop')

# Image filename
image_filename = "Memes.png"
#-----------------UPLOAD IMAGE HERE^^----------------------------------------------------------------------------------------------------------------------------

# Full path to the image file
image_path = os.path.join(desktop_path, image_filename)

# Check if the image file exists
if os.path.exists(image_path):
    # Convert the image to raw binary values
    raw_data = convert_image_to_raw(image_path)
    
    # Define the output file path
    output_file = os.path.join(desktop_path, "raw_picture_data.bin")  # Output file in binary format
    
    # Write the raw binary data to a binary file
    with open(output_file, 'wb') as file:
        file.write(raw_data)
    
    print(f"Raw binary data written to {output_file}")
else:
    print("Image file not found on the desktop.")
