# Altera-DE1-FPGA-Development-Board-VGA-Controller-And-Image-Viewer
A VGA controller where you can upload a photo onto the onboard FLASH and view it via the VGA port.

////////////////////////////////////////////////////////////////////////////////////////
This is a fully functioning VGA controller with easy user controls.

To upload your own photos and content follow the steps below;

----------------------------------------- Setup -----------------------------------------
 
1. Download the Terasic - DE1 Control Panel provided in the "DE-1 CD-ROM" 
--> This CD-ROM is 100% owned and distibuted by the board company, I am just putting files here for ease of use
--> Open the control panel: DE1_control_panel\DE1_ControlPanel.exe

2. Turn on the dev board and press the "CONNECT" button

3. Once connected, change memory type to "FLASH (200000h WORDS, 4 MB)"

4. Under "Random Accesss" select "Chip Erase (60 sec)" for maximum stability

------------------------------------ Image Conversion ------------------------------------

5. Find any picture you want, open it in paint

6. In paint, click "Resize" in the top left

7. Select "Pixels", set the Horizontal Pixels to 640 and the Veritcal Pixels to 480

8. Press okay and save resulting image as a PNG on your desktop

9. Open the "ImageConverterFLASH.py" Python script I made and attached

10. Change the "image_filename" to the name you saved the image as in your desktop

11. Run the program, it will put the raw RGB pixel data on your desktop labeled "raw_picture_data.bin"

------------------------------------ Writing To FLASH ------------------------------------

12. Reopen the Terasic-DE1 Control Panel

13. Under "Sequential Write" check mark the box called "File Length"

14. Press "Write a File to Memory" and select the .bin file the Python script output

15. Once finished you can know use the image with the provided code!

----------------------------------------- Misc ------------------------------------------

-Each image only takes up 307,200 address lines in the FLASH module (which is 4 MB)
--Feel free to write multiple images to the FLASH, 
  just update the Pthon code to take multiple images and make a big combined file to write
--The code as of right now just using the pixel position to set the address on teh FLASH, 
  so that would also have to be updated to pick between different photos

***The Verilog code is attached, the only thing you have to do prior to compiling is to upload the default pin assignments***
-Those can be found at: DE1_pin_assignments.csv

-There is also an attached folder called "FailedSDRAM" from where I intially tried to do this project with the onboard SDRAM rather than FLASH
-If you would like to use the SDRAM instead, be my guest and try to figure out the flaws with the files in there. It's not too far off from working...I think.


