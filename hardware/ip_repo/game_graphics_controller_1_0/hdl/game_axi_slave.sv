`timescale 1 ns / 1 ps

module game_axi_slave #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 16
)
(
    // Game control outputs
    output logic [9:0] player_x_out,
    output logic [9:0] player_y_out,
    output logic [7:0] player_tile_out,
    output logic player_enable_out,
    output logic [31:0] palette_out [8],

    // Status inputs
    input logic [31:0] frame_count_in,

    // Tilemap BRAM interface
    output logic tilemap_ena,
    output logic [3:0] tilemap_wea,
    output logic [10:0] tilemap_addra,
    output logic [31:0] tilemap_dina,
    input logic [31:0] tilemap_douta,

    // AXI4-Lite interface
    input logic  S_AXI_ACLK,
    input logic  S_AXI_ARESETN,
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input logic [2:0] S_AXI_AWPROT,
    input logic  S_AXI_AWVALID,
    output logic  S_AXI_AWREADY,
    input logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input logic  S_AXI_WVALID,
    output logic  S_AXI_WREADY,
    output logic [1:0] S_AXI_BRESP,
    output logic  S_AXI_BVALID,
    input logic  S_AXI_BREADY,
    input logic [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input logic [2:0] S_AXI_ARPROT,
    input logic  S_AXI_ARVALID,
    output logic  S_AXI_ARREADY,
    output logic [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output logic [1:0] S_AXI_RRESP,
    output logic  S_AXI_RVALID,
    input logic  S_AXI_RREADY
);

    // AXI4LITE signals
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic axi_awready;
    logic axi_wready;
    logic [1:0] axi_bresp;
    logic axi_bvalid;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0] axi_rresp;
    logic axi_rvalid;

    localparam integer ADDR_LSB = 2;  // For 32-bit addressing
    localparam integer OPT_MEM_ADDR_BITS = 13;

    // Game control registers
    logic [31:0] player_x_reg;
    logic [31:0] player_y_reg;
    logic [31:0] player_control_reg;  // [7:0]=tile_id, [8]=enable
    logic [31:0] palette_regs [8];

    // BRAM read wait states
    logic [1:0] bram_read_wait;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_araddr_latched;

    logic slv_reg_rden;
    logic slv_reg_wren;
    logic [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer byte_index;
    logic aw_en;

    // I/O Connections
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY = axi_wready;
    assign S_AXI_BRESP = axi_bresp;
    assign S_AXI_BVALID = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA = axi_rdata;
    assign S_AXI_RRESP = axi_rresp;
    assign S_AXI_RVALID = axi_rvalid;

    // Connect to outputs
    assign player_x_out = player_x_reg[9:0];
    assign player_y_out = player_y_reg[9:0];
    assign player_tile_out = player_control_reg[7:0];
    assign player_enable_out = player_control_reg[8];
    assign palette_out = palette_regs;

    // Write address ready
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Write address latching
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_awaddr <= 0;
        else if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en)
            axi_awaddr <= S_AXI_AWADDR;
    end

    // Write data ready
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_wready <= 1'b0;
        else if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en)
            axi_wready <= 1'b1;
        else
            axi_wready <= 1'b0;
    end

    // Write response
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            player_x_reg <= 32'd160;  // Start at center-ish
            player_y_reg <= 32'd120;
            player_control_reg <= 32'h101;  // tile_id=1, enabled

            // Initialize palette with default colors (CGA-like)
            palette_regs[0] <= 32'h000_A00;  // Black, Blue
            palette_regs[1] <= 32'h0AA_0A0;  // Cyan, Green
            palette_regs[2] <= 32'h0A0_A00;  // Magenta, Red
            palette_regs[3] <= 32'hAAA_A50;  // Lt Gray, Brown
            palette_regs[4] <= 32'h55F_555;  // Lt Blue, Dk Gray
            palette_regs[5] <= 32'h5FF_5F5;  // Lt Cyan, Lt Green
            palette_regs[6] <= 32'hF5F_F55;  // Lt Magenta, Lt Red
            palette_regs[7] <= 32'hFFF_FF5;  // White, Yellow
        end else if (slv_reg_wren) begin
            // Decode address and write to appropriate register
            case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                2048: begin  // Player X
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                        if (S_AXI_WSTRB[byte_index])
                            player_x_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
                2049: begin  // Player Y
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                        if (S_AXI_WSTRB[byte_index])
                            player_y_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
                2050: begin  // Player control
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                        if (S_AXI_WSTRB[byte_index])
                            player_control_reg[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                end
                default: begin
                    // Check if it's palette registers (2052-2059)
                    if (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 2052 &&
                        axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 2060) begin
                        for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                            if (S_AXI_WSTRB[byte_index])
                                palette_regs[axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 2052][(byte_index*8) +: 8]
                                    <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                end
            endcase
        end
    end

    // Tilemap BRAM write access
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            tilemap_ena <= 1'b0;
            tilemap_wea <= 4'b0;
            tilemap_addra <= 11'b0;
            tilemap_dina <= 32'b0;
        end else if (slv_reg_wren && axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
            tilemap_ena <= 1'b1;
            tilemap_wea <= S_AXI_WSTRB;
            tilemap_addra <= axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
            tilemap_dina <= S_AXI_WDATA;
        end else if (slv_reg_rden && axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
            tilemap_ena <= 1'b1;
            tilemap_wea <= 4'b0;
            tilemap_addra <= axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
            tilemap_dina <= 32'b0;
        end else if (bram_read_wait != 0 && axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
            tilemap_ena <= 1'b1;
            tilemap_wea <= 4'b0;
            tilemap_addra <= axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB];
            tilemap_dina <= 32'b0;
        end else begin
            tilemap_ena <= 1'b0;
            tilemap_wea <= 4'b0;
        end
    end

    // Write response valid
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_bvalid <= 0;
            axi_bresp <= 2'b0;
        end else if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
            axi_bvalid <= 1'b1;
            axi_bresp <= 2'b0;  // OKAY
        end else if (S_AXI_BREADY && axi_bvalid) begin
            axi_bvalid <= 1'b0;
        end
    end

    // Read address ready
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_arready <= 1'b0;
            axi_araddr <= 32'b0;
        end else if (~axi_arready && S_AXI_ARVALID) begin
            axi_arready <= 1'b1;
            axi_araddr <= S_AXI_ARADDR;
        end else begin
            axi_arready <= 1'b0;
        end
    end

    // Read valid with BRAM wait states
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_rvalid <= 0;
            axi_rresp <= 0;
            bram_read_wait <= 0;
            axi_araddr_latched <= 0;
        end else if (axi_arready && S_AXI_ARVALID && ~axi_rvalid && bram_read_wait == 2'b00) begin
            axi_araddr_latched <= axi_araddr;
            bram_read_wait <= 2'b01;
            axi_rvalid <= 0;
            axi_rresp <= 2'b0;
        end else if (bram_read_wait == 2'b01) begin
            bram_read_wait <= 2'b10;
            axi_rvalid <= 0;
        end else if (bram_read_wait == 2'b10) begin
            bram_read_wait <= 0;
            axi_rvalid <= 1;
            axi_rresp <= 2'b0;
        end else if (axi_rvalid && S_AXI_RREADY) begin
            axi_rvalid <= 1'b0;
        end
    end

    // Read data mux
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always_comb begin
        if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 1200) begin
            reg_data_out = tilemap_douta;
        end else case (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2048: reg_data_out = player_x_reg;
            2049: reg_data_out = player_y_reg;
            2050: reg_data_out = player_control_reg;
            2060: reg_data_out = frame_count_in;
            default: begin
                if (axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] >= 2052 &&
                    axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] < 2060)
                    reg_data_out = palette_regs[axi_araddr_latched[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] - 2052];
                else
                    reg_data_out = 0;
            end
        endcase
    end

    // Read data output
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN)
            axi_rdata <= 0;
        else if (bram_read_wait == 2'b10)
            axi_rdata <= reg_data_out;
    end

endmodule
