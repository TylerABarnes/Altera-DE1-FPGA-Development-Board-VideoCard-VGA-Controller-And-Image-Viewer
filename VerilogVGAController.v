module VerilogVGAController (
    input wire CLOCK_50,
    input wire reset,
    output reg Hsync,
    output reg Vsync,
    output reg [3:0] VGA_R,
    output reg [3:0] VGA_G,
    output reg [3:0] VGA_B,
    output reg VGA_HS,
    output reg VGA_VS,

    // FLASH signals
    output reg [21:0] FL_ADDR,   // FLASH Address
    inout wire [7:0] FL_DQ,      // FLASH Data
    output reg FL_OE_N,          // FLASH Output Enable
    output reg FL_RST_N,         // FLASH Reset
    output reg FL_WE_N           // FLASH Write Enable
);

// VGA Controller constants based on timing specifications
localparam HOR_RES   = 640;  // Horizontal resolution
localparam VER_RES   = 480;  // Vertical resolution
localparam HOR_FRONT = 16;   // Horizontal Front Porch
localparam HOR_SYNC  = 96;   // Horizontal Sync pulse width
localparam HOR_BACK  = 48;   // Horizontal Back Porch
localparam VER_FRONT = 10;   // Vertical Front Porch
localparam VER_SYNC  = 2;    // Vertical Sync pulse width
localparam VER_BACK  = 33;   // Vertical Back Porch
localparam PIXEL_CLK = 25;   // Pixel clock in MHz

// Horizontal and Vertical counters
reg [9:0] h_counter = 0; // Horizontal counter
reg [9:0] v_counter = 0; // Vertical counter

// Pixel valid signal
reg pixel_valid;

// Temporary storage for pixel data from FLASH
reg [7:0] flash_data;
reg [21:0] byte_addr;  // Address space to handle the entire image

// FLASH read states
reg [3:0] flash_state = 0;

// Initialize VGA signals to default values
initial begin
    Hsync = 1'b0;
    Vsync = 1'b0;
    VGA_R = 4'b0000;
    VGA_G = 4'b0000;
    VGA_B = 4'b0000;
    VGA_HS = 1'b0;
    VGA_VS = 1'b0;
    FL_RST_N = 1'b1;  // Assume FLASH is not in reset
    FL_WE_N = 1'b1;   // Assume FLASH is not in write mode
end

// Horizontal Counter
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        h_counter <= 0;
    end else begin
        if (h_counter == HOR_RES + HOR_FRONT + HOR_SYNC + HOR_BACK - 1) begin
            h_counter <= 0;
        end else begin
            h_counter <= h_counter + 1;
        end
    end
end

// Vertical Counter
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        v_counter <= 0;
    end else if (h_counter == HOR_RES + HOR_FRONT + HOR_SYNC + HOR_BACK - 1) begin
        if (v_counter == VER_RES + VER_FRONT + VER_SYNC + VER_BACK - 1) begin
            v_counter <= 0;
        end else begin
            v_counter <= v_counter + 1;
        end
    end
end

// Generate sync signals
always @(*) begin
    VGA_HS = (h_counter < HOR_RES + HOR_FRONT) || (h_counter >= HOR_RES + HOR_FRONT + HOR_SYNC) ? 1 : 0;
    VGA_VS = (v_counter < VER_RES + VER_FRONT) || (v_counter >= VER_RES + VER_FRONT + VER_SYNC) ? 1 : 0;
end

// Generate pixel_valid signal
always @(*) begin
    pixel_valid = (h_counter < HOR_RES) && (v_counter < VER_RES) ? 1 : 0;
end

// FLASH control signals and state machine
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        FL_OE_N <= 1'b1;
        flash_state <= 0;
    end else begin
        case (flash_state)
            0: begin
                if (pixel_valid) begin
                    // Calculate the byte address based on VGA coordinates
                    byte_addr = (v_counter * HOR_RES) + h_counter;

                    // Set the FLASH address
                    FL_ADDR <= byte_addr;

                    // Assert the Output Enable signal to start reading
                    FL_OE_N <= 1'b0;

                    flash_state <= 1;
                end
            end
            1: begin
                // Wait for tACC (90 ns at 50 MHz = 5 cycles)
                flash_state <= 2;
            end
            2: begin
                // Read the data from FL_DQ
                flash_data <= FL_DQ;

                // Deassert Output Enable signal
                FL_OE_N <= 1'b1;

                flash_state <= 3;
            end
            3: begin
                // Done reading the pixel, go back to idle state
                flash_state <= 0;
            end
        endcase
    end
end

// Assign pixel color based on FLASH data
always @(posedge CLOCK_50) begin
    if (pixel_valid) begin
        // Extract color information from flash_data
		  // The FLASH has 8-bits of data at each address, 
		  // so each address has 3-bits of RED, 3-bits of Green, and 2-bits of Blue
		  // This FPGA board using a 4-bit DAC so that's where the fill comes from
        VGA_R <= {flash_data[7:5], 1'b0};  // Red component (3 bits) extended to 4 bits
        VGA_G <= {flash_data[4:2], 1'b0};  // Green component (3 bits) extended to 4 bits
        VGA_B <= {flash_data[1:0], 2'b00}; // Blue component (2 bits) extended to 4 bits
    end else begin
        // If not a valid pixel, set default values
        VGA_R <= 4'b0000;
        VGA_G <= 4'b0000;
        VGA_B <= 4'b0000;
    end
end

endmodule
