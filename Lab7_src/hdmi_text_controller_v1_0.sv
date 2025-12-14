//Provided HDMI_Text_controller_v1_0 for HDMI AXI4 IP 
//Fall 2024 Distribution

//Modified 3/10/24 by Zuofu
//Updated 11/18/24 by Zuofu


`timescale 1 ns / 1 ps

module hdmi_text_controller_v1_0 #
(
    // Parameters of Axi Slave Bus Interface S00_AXI
    // Modify parameters as necessary for access of full VRAM range

    parameter integer C_AXI_DATA_WIDTH	= 32,
    parameter integer C_AXI_ADDR_WIDTH	= 16 
)
(
    // Users to add ports here

    output logic hdmi_clk_n,
    output logic hdmi_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p,

    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface AXI
    input logic  axi_aclk,
    input logic  axi_aresetn,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_awaddr,
    input logic [2 : 0] axi_awprot,
    input logic  axi_awvalid,
    output logic  axi_awready,
    input logic [C_AXI_DATA_WIDTH-1 : 0] axi_wdata,
    input logic [(C_AXI_DATA_WIDTH/8)-1 : 0] axi_wstrb,
    input logic  axi_wvalid,
    output logic  axi_wready,
    output logic [1 : 0] axi_bresp,
    output logic  axi_bvalid,
    input logic  axi_bready,
    input logic [C_AXI_ADDR_WIDTH-1 : 0] axi_araddr,
    input logic [2 : 0] axi_arprot,
    input logic  axi_arvalid,
    output logic  axi_arready,
    output logic [C_AXI_DATA_WIDTH-1 : 0] axi_rdata,
    output logic [1 : 0] axi_rresp,
    output logic  axi_rvalid,
    input logic  axi_rready
);

//additional logic variables as necessary to support VGA, and HDMI modules.
// Clock signals
    logic clk_25MHz, clk_125MHz;
    logic locked;
    // VGA signals
    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;
    //Color
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    // User logic from AXI
    logic [31:0] vram_data;
    logic [31:0] control_reg;
    logic [31:0] palette_data [8];

    logic bram_ena;
    logic [3:0] bram_wea;
    logic [10:0] bram_addra;
    logic [31:0] bram_dina;
    logic [31:0] bram_douta;

    // Initialize status regs
    logic [31:0] frame_count;      
    logic [31:0] drawx_captured;   
    logic [31:0] drawy_captured;
    
    //Pixel drawing logic
    logic [6:0] char_col;   //80 cols
    logic [4:0] char_row;   //30 rows
    logic [2:0] pixel_x;    //8 * 16 pixels
    logic [3:0] pixel_y;
    
    //VRAM access
    logic [11:0] char_index;  //2400
    logic [10:0] vram_addr;  //1200 (need 11 bits for 0-1199)
    logic [1:0] byte_offset;    //which byte to choose
    logic [7:0] char_code;   //ASCII code from VRAM, highest bit for inverse character
    
    //font ROM
    logic [10:0] font_addr; //char_code[6:0] + pixel_y[3:0]
    logic [7:0] font_row;   //8 pixels this row
    logic pixel_bit;
       
    //control signals
    logic [3:0] fg_r, fg_g, fg_b; 
    logic [3:0] bg_r, bg_g, bg_b;
    logic inverse_bit;  //inverse character

// Instantiation of Axi Bus Interface AXI
hdmi_text_controller_v1_0_AXI # ( 
    .C_S_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH)
) hdmi_text_controller_v1_0_AXI_inst (
    .control_reg_out(control_reg),
    .palette_out(palette_data),

    .bram_ena(bram_ena),
    .bram_wea(bram_wea),
    .bram_addra(bram_addra),
    .bram_dina(bram_dina),
    .bram_douta(bram_douta),
    // week 2 change end

    .frame_count_in(frame_count),
    .drawx_in(drawx_captured),
    .drawy_in(drawy_captured),
    .S_AXI_ACLK(axi_aclk),
    .S_AXI_ARESETN(axi_aresetn),
    .S_AXI_AWADDR(axi_awaddr),
    .S_AXI_AWPROT(axi_awprot),
    .S_AXI_AWVALID(axi_awvalid),
    .S_AXI_AWREADY(axi_awready),
    .S_AXI_WDATA(axi_wdata),
    .S_AXI_WSTRB(axi_wstrb),
    .S_AXI_WVALID(axi_wvalid),
    .S_AXI_WREADY(axi_wready),
    .S_AXI_BRESP(axi_bresp),
    .S_AXI_BVALID(axi_bvalid),
    .S_AXI_BREADY(axi_bready),
    .S_AXI_ARADDR(axi_araddr),
    .S_AXI_ARPROT(axi_arprot),
    .S_AXI_ARVALID(axi_arvalid),
    .S_AXI_ARREADY(axi_arready),
    .S_AXI_RDATA(axi_rdata),
    .S_AXI_RRESP(axi_rresp),
    .S_AXI_RVALID(axi_rvalid),
    .S_AXI_RREADY(axi_rready)
);

// Initialize blk modules here
blk_mem_gen_0 vram_bram (
    .clka(axi_aclk),
    .ena(bram_ena),
    .wea(bram_wea),
    .addra(bram_addra),
    .dina(bram_dina),
    .douta(bram_douta),
    
    .clkb(clk_25MHz),
    .enb(1'b1),
    .web(4'b0),
    .addrb(vram_addr),
    .dinb(32'b0),
    .doutb(vram_data)
);

//Instiante clocking wizard, VGA sync generator modules, and VGA-HDMI IP here. For a hint, refer to the provided
//top-level from the previous lab. You should get the IP to generate a valid HDMI signal (e.g. blue screen or gradient)
//prior to working on the text drawing.

// User logic ends
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(~axi_aresetn),
        .locked(locked),
        .clk_in1(axi_aclk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(~axi_aresetn),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );   
    
    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(~axi_aresetn),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_clk_p),          
        .TMDS_CLK_N(hdmi_clk_n),          
        .TMDS_DATA_P(hdmi_tx_p),         
        .TMDS_DATA_N(hdmi_tx_n)          
    );

    // calculation
    assign char_col = drawX[9:3];   //divided by 8
    assign char_row = drawY[9:4];   //divided by 16
    // assign pixel_x = drawX[2:0];
    // assign pixel_y = drawY[3:0];
    
    assign char_index = char_row * 7'd80 + char_col; // char_index = char_row * 80 + char_col
    assign vram_addr = char_index[11:1];    // divide by 2 in wk2 (2 bytes per char)
    // assign byte_offset = char_index[1:0];   // which byte 
    
    // Week 2 change begin:

    // CYCLE 1
    logic [10:0] vram_addr_c1; 
    logic byte_offset_c1;  
    logic [2:0] pixel_x_c1;
    logic [3:0] pixel_y_c1;
    always_ff @(posedge clk_25MHz) begin
        vram_addr_c1 <= vram_addr;     
        byte_offset_c1 <= char_index[0];  
        pixel_x_c1 <= drawX[2:0];
        pixel_y_c1 <= drawY[3:0];
    end

    // CYCLE 2
    logic byte_offset_c2;  
    logic [2:0] pixel_x_c2;
    logic [3:0] pixel_y_c2;
    logic [31:0] vram_data_c2;
    always_ff @(posedge clk_25MHz) begin
        byte_offset_c2 <= byte_offset_c1; 
        pixel_x_c2 <= pixel_x_c1;
        pixel_y_c2 <= pixel_y_c1;
        vram_data_c2 <= vram_data; 
    end

    // CYCLE 3: Extract character data
    logic [7:0] char_code_c3;
    logic [2:0] pixel_x_c3;
    logic [3:0] pixel_y_c3;
    logic [15:0] char_data_c3;
    always_ff @(posedge clk_25MHz) begin
        pixel_x_c3 <= pixel_x_c2;
        pixel_y_c3 <= pixel_y_c2;
        case (byte_offset_c2)  
            1'b0: char_data_c3 <= vram_data_c2[15:0];   
            1'b1: char_data_c3 <= vram_data_c2[31:16];  
        endcase
    end
    
    // Extract fields from char_data_c3 (wk2)
    logic [3:0] fg_idx_c3, bg_idx_c3;
    assign char_code_c3 = char_data_c3[15:8];  // ASCII code
    assign fg_idx_c3 = char_data_c3[7:4];     // fg color index
    assign bg_idx_c3 = char_data_c3[3:0];     // bg color index
    assign inverse_bit = char_code_c3[7];      // inverse bit same as wk1

    // //get character code from VRAM byte
    // always_comb begin
    //     case (byte_offset)
    //         2'b00: char_code = vram_data[7:0];
    //         2'b01: char_code = vram_data[15:8];
    //         2'b10: char_code = vram_data[23:16];
    //         2'b11: char_code = vram_data[31:24];
    //     endcase
    // end
    
    //Font ROM
    assign font_addr = {char_code_c3[6:0], pixel_y_c3};
    font_rom font_rom_inst (
        .addr(font_addr),      
        .data(font_row)        
    );

    // deal with coloring
    // get pixel_bit, be careful about the difference in order of pixel_x and font_row
    assign pixel_bit = font_row[7 - pixel_x_c3];

    logic [11:0] palette_colors [16];
    assign palette_colors[0]  = palette_data[0][11:0];
    assign palette_colors[1]  = palette_data[0][27:16];
    assign palette_colors[2]  = palette_data[1][11:0];
    assign palette_colors[3]  = palette_data[1][27:16];
    assign palette_colors[4]  = palette_data[2][11:0];
    assign palette_colors[5]  = palette_data[2][27:16];
    assign palette_colors[6]  = palette_data[3][11:0];
    assign palette_colors[7]  = palette_data[3][27:16];
    assign palette_colors[8]  = palette_data[4][11:0];
    assign palette_colors[9]  = palette_data[4][27:16];
    assign palette_colors[10] = palette_data[5][11:0];
    assign palette_colors[11] = palette_data[5][27:16];
    assign palette_colors[12] = palette_data[6][11:0];
    assign palette_colors[13] = palette_data[6][27:16];
    assign palette_colors[14] = palette_data[7][11:0];
    assign palette_colors[15] = palette_data[7][27:16];

    assign fg_r = palette_colors[fg_idx_c3][11:8];
    assign fg_g = palette_colors[fg_idx_c3][7:4];
    assign fg_b = palette_colors[fg_idx_c3][3:0];
    assign bg_r = palette_colors[bg_idx_c3][11:8];
    assign bg_g = palette_colors[bg_idx_c3][7:4];
    assign bg_b = palette_colors[bg_idx_c3][3:0];

    // color config
//    assign fg_r = control_reg_c2[27:24];
//    assign fg_g = control_reg_c2[23:20];
//    assign fg_b = control_reg_c2[19:16];
//    assign bg_r = control_reg_c2[11:8];
//    assign bg_g = control_reg_c2[7:4];
//    assign bg_b = control_reg_c2[3:0];
    // assign inverse_bit = char_code_c2[7];
    // Week 2 change end
    
    // color output logistics
    always_comb begin
        if (vde) begin
            if (pixel_bit ^ inverse_bit) begin
                red   = fg_r;    
                green = fg_g;    
                blue  = fg_b;    
            end else begin
                red   = bg_r;    
                green = bg_g;    
                blue  = bg_b;    
            end
        end else begin
            red   = 4'h0;
            green = 4'h0;
            blue  = 4'h0;
        end
    end
           
    // Frame Counter
    logic vsync_prev; 
    always_ff @(posedge clk_25MHz) begin
        if (~axi_aresetn) begin
            frame_count <= 32'h0;
            vsync_prev <= 1'b0;
            drawx_captured <= 32'h0;
            drawy_captured <= 32'h0;
        end
        else begin
            vsync_prev <= vsync;
            if (vsync && ~vsync_prev) begin
                frame_count <= frame_count + 1'b1;  
                drawx_captured <= {22'b0, drawX};   
                drawy_captured <= {22'b0, drawY};   
            end
        end
    end
    
endmodule
