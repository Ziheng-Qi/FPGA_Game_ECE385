//-------------------------------------------------------------------------
//    game_graphics_controller.sv                                         --
//    ECE 385 Final Project - UIUC Treasure Hunt                          --
//    Ziheng Qi & Haoru Li                                                --
//    Fall 2024                                                           --
//                                                                         --
//    Custom AXI4-Lite graphics controller for tile-based game            --
//    Features:                                                           --
//    - 40x30 tile map (16x16 pixel tiles)                                --
//    - Tile graphics BRAM (up to 256 unique tiles)                       --
//    - Sprite layer for player character                                 --
//    - 16-color palette (RGB444)                                         --
//-------------------------------------------------------------------------

`timescale 1 ns / 1 ps

module game_graphics_controller_v1_0 #
(
    parameter integer C_AXI_DATA_WIDTH = 32,
    parameter integer C_AXI_ADDR_WIDTH = 16
)
(
    // HDMI output ports
    output logic hdmi_clk_n,
    output logic hdmi_clk_p,
    output logic [2:0] hdmi_tx_n,
    output logic [2:0] hdmi_tx_p,

    // AXI4-Lite slave interface
    input logic  axi_aclk,
    input logic  axi_aresetn,
    input logic [C_AXI_ADDR_WIDTH-1:0] axi_awaddr,
    input logic [2:0] axi_awprot,
    input logic  axi_awvalid,
    output logic  axi_awready,
    input logic [C_AXI_DATA_WIDTH-1:0] axi_wdata,
    input logic [(C_AXI_DATA_WIDTH/8)-1:0] axi_wstrb,
    input logic  axi_wvalid,
    output logic  axi_wready,
    output logic [1:0] axi_bresp,
    output logic  axi_bvalid,
    input logic  axi_bready,
    input logic [C_AXI_ADDR_WIDTH-1:0] axi_araddr,
    input logic [2:0] axi_arprot,
    input logic  axi_arvalid,
    output logic  axi_arready,
    output logic [C_AXI_DATA_WIDTH-1:0] axi_rdata,
    output logic [1:0] axi_rresp,
    output logic  axi_rvalid,
    input logic  axi_rready
);

    // Clock signals
    logic clk_25MHz, clk_125MHz;
    logic locked;

    // VGA signals
    logic [9:0] drawX, drawY;
    logic hsync, vsync, vde;

    // Color output
    logic [3:0] red, green, blue;

    // Tile map BRAM interface (40x30 = 1200 tiles)
    logic tilemap_ena, tilemap_enb;
    logic [3:0] tilemap_wea;
    logic [10:0] tilemap_addra, tilemap_addrb;
    logic [31:0] tilemap_dina, tilemap_douta, tilemap_doutb;

    // Tile graphics BRAM interface (92 tiles * 64 words = 5888 words, requires 13-bit address)
    logic tilegfx_enb;
    logic [12:0] tilegfx_addrb;  // 13-bit for 8192 words BRAM
    logic [31:0] tilegfx_doutb;

    // Player sprite registers (AXI accessible)
    logic [9:0] player_x, player_y;
    logic [7:0] player_tile_id;
    logic player_enable;

    // Palette registers
    logic [31:0] palette_data [8];

    // Frame counter
    logic [31:0] frame_count;

    //=========================================================================
    // CLOCK WIZARD - Generate 25MHz and 125MHz from 100MHz input
    //=========================================================================
    clk_wiz_0 clk_wiz_inst (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(~axi_aresetn),
        .locked(locked),
        .clk_in1(axi_aclk)
    );

    //=========================================================================
    // VGA CONTROLLER - Generate sync signals and pixel coordinates
    //=========================================================================
    vga_controller vga_inst (
        .pixel_clk(clk_25MHz),
        .reset(~axi_aresetn),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );

    //=========================================================================
    // TILEMAP BRAM - Dual port: A for AXI write, B for rendering read
    //=========================================================================
    blk_mem_gen_tilemap tilemap_bram (
        .clka(axi_aclk),
        .ena(tilemap_ena),
        .wea(tilemap_wea),
        .addra(tilemap_addra),
        .dina(tilemap_dina),
        .douta(tilemap_douta),

        .clkb(clk_25MHz),
        .enb(tilemap_enb),
        .web(4'b0),
        .addrb(tilemap_addrb),
        .dinb(32'b0),
        .doutb(tilemap_doutb)
    );

    //=========================================================================
    // TILE GRAPHICS BRAM - Single port B for rendering read only
    // Port A can be used for initialization via COE file
    //=========================================================================
    blk_mem_gen_tilegfx tilegfx_bram (
        .clka(axi_aclk),    // FIXED: Connect to clock for COE initialization
        .ena(1'b0),         // Port A disabled during runtime
        .wea(4'b0),
        .addra(13'b0),      // 13-bit to match 8192 words BRAM
        .dina(32'b0),
        .douta(),

        .clkb(clk_25MHz),
        .enb(tilegfx_enb),
        .web(4'b0),
        .addrb(tilegfx_addrb),
        .dinb(32'b0),
        .doutb(tilegfx_doutb)
    );

    //=========================================================================
    // AXI SLAVE INTERFACE - Handle MicroBlaze register access
    //=========================================================================
    game_axi_slave #(
        .C_S_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH)
    ) axi_slave_inst (
        .player_x_out(player_x),
        .player_y_out(player_y),
        .player_tile_out(player_tile_id),
        .player_enable_out(player_enable),
        .palette_out(palette_data),

        .frame_count_in(frame_count),

        .tilemap_ena(tilemap_ena),
        .tilemap_wea(tilemap_wea),
        .tilemap_addra(tilemap_addra),
        .tilemap_dina(tilemap_dina),
        .tilemap_douta(tilemap_douta),

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

    //=========================================================================
    // TILE RENDERER - Convert drawX/drawY to tile graphics
    //=========================================================================
    logic hsync_delayed, vsync_delayed, vde_delayed;

    tile_renderer tile_renderer_inst (
        .clk(clk_25MHz),
        .reset(~axi_aresetn),

        .drawX(drawX),
        .drawY(drawY),
        .vde(vde),
        .hsync_in(hsync),
        .vsync_in(vsync),

        .tilemap_addr(tilemap_addrb),
        .tilemap_data(tilemap_doutb),
        .tilemap_en(tilemap_enb),

        .tilegfx_addr(tilegfx_addrb),
        .tilegfx_data(tilegfx_doutb),
        .tilegfx_en(tilegfx_enb),

        .player_x(player_x),
        .player_y(player_y),
        .player_tile_id(player_tile_id),
        .player_enable(player_enable),

        .palette_data(palette_data),

        .red(red),
        .green(green),
        .blue(blue),
        
        .hsync_out(hsync_delayed),
        .vsync_out(vsync_delayed),
        .vde_out(vde_delayed)
    );

    //=========================================================================
    // HDMI TRANSMITTER - Convert VGA to HDMI
    //=========================================================================
    hdmi_tx_0 hdmi_tx_inst (
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        .rst(~axi_aresetn),
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync_delayed),  // Use delayed syncs to match pipeline latency
        .vsync(vsync_delayed),
        .vde(vde_delayed),
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        .TMDS_CLK_P(hdmi_clk_p),
        .TMDS_CLK_N(hdmi_clk_n),
        .TMDS_DATA_P(hdmi_tx_p),
        .TMDS_DATA_N(hdmi_tx_n)
    );

    //=========================================================================
    // FRAME COUNTER - Count vsync pulses for timing
    //=========================================================================
    logic vsync_prev;
    always_ff @(posedge clk_25MHz) begin
        if (~axi_aresetn) begin
            frame_count <= 32'h0;
            vsync_prev <= 1'b0;
        end else begin
            vsync_prev <= vsync;
            if (vsync && ~vsync_prev)
                frame_count <= frame_count + 1'b1;
        end
    end

endmodule
