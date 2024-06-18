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

    // SDRAM signals - Organized as 1M x 16 bits x 4 banks
    output reg [11:0] DRAM_ADDR,
    inout wire [15:0] DRAM_DQ,
    output reg DRAM_BA_0,        // SDRAM Bank Address[0]
    output reg DRAM_BA_1,        // SDRAM Bank Address[1]
    output reg DRAM_LDQM,        // SDRAM Low-byte Data Mask
    output reg DRAM_UDQM,        // SDRAM High-byte Data Mask 
    output reg DRAM_RAS_N,       // SDRAM Row Address Strobe
    output reg DRAM_CAS_N,       // SDRAM Column Address Strobe
    output reg DRAM_CKE,         // SDRAM Clock Enable
    output reg DRAM_CLK,         // SDRAM Clock
    output reg DRAM_WE_N,        // SDRAM Write Enable
    output reg DRAM_CS_N         // SDRAM Chip Select 
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

// Temporary storage for pixel data from SDRAM
reg [15:0] dram_data;
reg [21:0] byte_addr;  // Increased size to handle larger address space

// Additional address variables
reg [11:0] row_addr;
reg [9:0] col_addr;
reg [1:0] bank_addr;

// SDRAM initialization states
reg [3:0] init_state = 0;
reg [15:0] sdram_mode_reg = 16'b0000_0010_0011_0000; // Mode register: burst length = 1, CAS latency = 3

// SDRAM read states
reg [3:0] sdram_state = 0;

// Initialize VGA signals to default values
initial begin
    Hsync = 1'b0;
    Vsync = 1'b0;
    VGA_R = 4'b0000;
    VGA_G = 4'b0000;
    VGA_B = 4'b0000;
    VGA_HS = 1'b0;
    VGA_VS = 1'b0;
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

// SDRAM control signals and state machine
always @(posedge CLOCK_50 or posedge reset) begin
    if (reset) begin
        DRAM_CKE <= 1'b0;
        DRAM_CS_N <= 1'b1;
        DRAM_RAS_N <= 1'b1;
        DRAM_CAS_N <= 1'b1;
        DRAM_WE_N <= 1'b1;
        init_state <= 0;
        sdram_state <= 0;
    end else begin
        case (init_state)
            0: begin
                // Step 1: Assert CKE high
                DRAM_CKE <= 1'b1;
                init_state <= 1;
            end
            1: begin
                // Step 2: Issue a PRECHARGE ALL command
                DRAM_CS_N <= 1'b0;
                DRAM_RAS_N <= 1'b0;
                DRAM_CAS_N <= 1'b1;
                DRAM_WE_N <= 1'b0;
                DRAM_ADDR[10] <= 1'b1; // A10 high for precharge all
                init_state <= 2;
            end
            2: begin
                // Step 3: Issue 2 AUTO REFRESH commands
                DRAM_CS_N <= 1'b0;
                DRAM_RAS_N <= 1'b0;
                DRAM_CAS_N <= 1'b0;
                DRAM_WE_N <= 1'b1;
                init_state <= 3;
            end
            3: begin
                // Step 4: Issue second AUTO REFRESH command
                DRAM_CS_N <= 1'b0;
                DRAM_RAS_N <= 1'b0;
                DRAM_CAS_N <= 1'b0;
                DRAM_WE_N <= 1'b1;
                init_state <= 4;
            end
            4: begin
                // Step 5: Issue a LOAD MODE REGISTER command
                DRAM_CS_N <= 1'b0;
                DRAM_RAS_N <= 1'b0;
                DRAM_CAS_N <= 1'b0;
                DRAM_WE_N <= 1'b0;
                DRAM_ADDR <= sdram_mode_reg;
                init_state <= 5;
            end
            5: begin
                // Initialization done, transition to normal operation
                DRAM_CS_N <= 1'b1;
                DRAM_RAS_N <= 1'b1;
                DRAM_CAS_N <= 1'b1;
                DRAM_WE_N <= 1'b1;
                init_state <= 6;
            end
        endcase

        // SDRAM Read process
        if (init_state == 6) begin
            case (sdram_state)
                0: begin
                    if (pixel_valid) begin
                        // Calculate the byte address based on VGA coordinates
                        byte_addr = (v_counter * HOR_RES) + h_counter;
								//byte_addr = 22'b0000000000000000000000; ////////////////////////////////////////// TEST

                        // Calculate row, column, and bank addresses
                        row_addr = byte_addr[21:10];  // Higher bits for row address
                        col_addr = byte_addr[9:0];    // Lower bits for column address
                        bank_addr = 2'b00;            // Use the first bank for simplicity

                        // Step 1: Activate the row
                        DRAM_BA_0 <= bank_addr[0];
                        DRAM_BA_1 <= bank_addr[1];
                        DRAM_ADDR <= row_addr;
                        DRAM_CS_N <= 1'b0;
                        DRAM_RAS_N <= 1'b0;
                        DRAM_CAS_N <= 1'b1;
                        DRAM_WE_N <= 1'b1;

                        sdram_state <= 1;
                    end
                end
                1: begin
                    // Wait for tRCD (15 ns at 50 MHz = 3 cycles)
                    sdram_state <= 2;
                end
                2: begin
                    // Step 2: Issue a READ command
                    DRAM_ADDR <= col_addr;
                    DRAM_CS_N <= 1'b0;
                    DRAM_RAS_N <= 1'b1;
                    DRAM_CAS_N <= 1'b0;
                    DRAM_WE_N <= 1'b1;

                    sdram_state <= 3;
                end
                3: begin
                    // Wait for tCAS (3 cycles)
                    sdram_state <= 4;
                end
                4: begin
                    // Step 3: Read the data from DRAM_DQ
                    dram_data <= DRAM_DQ;

                    // Deassert DRAM control signals
                    DRAM_CS_N <= 1'b1;
                    DRAM_RAS_N <= 1'b1;
                    DRAM_CAS_N <= 1'b1;
                    DRAM_WE_N <= 1'b1;

                    sdram_state <= 5;
                end
                5: begin
                    // Done reading the pixel, go back to idle state
                    sdram_state <= 0;
                end
            endcase
        end
    end
end

// Assign pixel color based on SDRAM data
always @(posedge CLOCK_50) begin
    if (pixel_valid) begin
        // Extract color information from dram_data
        VGA_R <= dram_data[15:12]; // Red component (MSBs)
        VGA_G <= dram_data[11:8];  // Green component
        VGA_B <= dram_data[7:4];   // Blue component (LSBs)
		  //VGA_R <= 4'b0110; // Red ////////////////////////////////////////// TEST
        //VGA_G <= 4'b1010; // Green ////////////////////////////////////////// TEST
        //VGA_B <= 4'b1000; // Blue ////////////////////////////////////////// TEST
    end else begin
        // If not a valid pixel, set default values
        VGA_R <= 4'b0110;
        VGA_G <= 4'b1010;
        VGA_B <= 4'b1000;
    end
end

endmodule

//VGA_R,G,B Test✔
//Actually reading something written into memory --> It's accessing memory, just not correctly
//Timing
