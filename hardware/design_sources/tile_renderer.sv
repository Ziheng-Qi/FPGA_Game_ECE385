//-------------------------------------------------------------------------
//    tile_renderer.sv                                                    --
//    Core tile and sprite rendering engine                               --
//    Ziheng Qi & Haoru Li                                                --
//    Fall 2025                                                          --
//                                                                         --
//    Pipeline stages (8-stage pipeline for BRAM timing):                 --
//    Cycle 0a: Register pixel position to tile coordinates               --
//    Cycle 0b: Calculate tile index (multiplication needs full cycle)    --
//    Cycle 1: Register tilemap address selector                          --
//    Cycle 2: Register tilemap BRAM output and selector                  --
//    Cycle 3: Extract tile ID from registered data                       --
//    Cycle 4: Calculate tile graphics address and register selector      --
//    Cycle 5: Register tile graphics BRAM output and selector            --
//    Cycle 6: Extract pixel color from registered data                   --
//    Cycle 7: Apply palette, sprite overlay, output RGB                  --
//-------------------------------------------------------------------------

module tile_renderer (
    input  logic clk,
    input  logic reset,

    // Current pixel being drawn
    input  logic [9:0] drawX,
    input  logic [9:0] drawY,
    input  logic vde,              // Video display enable
    input  logic hsync_in,
    input  logic vsync_in,

    // Tilemap BRAM interface (read only from render side)
    output logic [10:0] tilemap_addr,
    input  logic [31:0] tilemap_data,
    output logic tilemap_en,

    // Tile graphics BRAM interface
    output logic [12:0] tilegfx_addr,  // 13-bit for 8192 words BRAM (92 tiles)
    input  logic [31:0] tilegfx_data,
    output logic tilegfx_en,

    // Player sprite position (in pixels)
    input  logic [9:0] player_x,
    input  logic [9:0] player_y,
    input  logic [7:0] player_tile_id,
    input  logic player_enable,

    // Color palette
    input  logic [31:0] palette_data [8],

    // RGB output
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue,
    
    // Delayed sync signals
    output logic hsync_out,
    output logic vsync_out,
    output logic vde_out
);

    // CONSTANTS
    localparam TILE_SIZE = 16;        // 16x16 pixels per tile
    localparam MAP_WIDTH = 40;        // 40 tiles wide
    localparam MAP_HEIGHT = 30;       // 30 tiles tall
    localparam WORDS_PER_TILE = 64;   // 16x16 pixels, 4 pixels per 32-bit word

    // PIPELINE STAGE 0a: Register tile and pixel positions + sprite calculation
    logic [5:0] tile_x_c0a, tile_y_c0a;    // Which tile (0-39, 0-29)
    logic [3:0] pixel_x_c0a, pixel_y_c0a;  // Pixel within tile (0-15)
    logic vde_c0a, hsync_c0a, vsync_c0a;

    // Sprite calculation (must be in same stage as drawX/drawY to maintain alignment)
    logic sprite_active_c0a;
    logic [3:0] sprite_pixel_x_c0a, sprite_pixel_y_c0a;

    always_ff @(posedge clk) begin
        if (reset) begin
            hsync_c0a <= 1'b0;
            vsync_c0a <= 1'b0;
            vde_c0a   <= 1'b0;
            sprite_active_c0a <= 1'b0;
        end else begin
            hsync_c0a <= hsync_in;
            vsync_c0a <= vsync_in;
            vde_c0a   <= vde;

            // Check if current pixel is within sprite bounds
            if (player_enable &&
                (drawX >= player_x) && (drawX < player_x + TILE_SIZE) &&
                (drawY >= player_y) && (drawY < player_y + TILE_SIZE)) begin
                sprite_active_c0a <= 1'b1;
                sprite_pixel_x_c0a <= drawX - player_x;
                sprite_pixel_y_c0a <= drawY - player_y;
            end else begin
                sprite_active_c0a <= 1'b0;
                sprite_pixel_x_c0a <= 4'b0;
                sprite_pixel_y_c0a <= 4'b0;
            end
        end

        tile_x_c0a  <= drawX[9:4];         // Divide by 16
        tile_y_c0a  <= drawY[9:4];
        pixel_x_c0a <= drawX[3:0];         // Modulo 16
        pixel_y_c0a <= drawY[3:0];
    end

    // PIPELINE STAGE 0b: Calculate tile index from registered coordinates
    logic [5:0] tile_x_c0, tile_y_c0;
    logic [3:0] pixel_x_c0, pixel_y_c0;
    logic [10:0] tile_index_c0;
    logic vde_c0, hsync_c0, vsync_c0;
    logic sprite_active_c0;
    logic [3:0] sprite_pixel_x_c0, sprite_pixel_y_c0;

    always_ff @(posedge clk) begin
        tile_x_c0  <= tile_x_c0a;
        tile_y_c0  <= tile_y_c0a;
        pixel_x_c0 <= pixel_x_c0a;
        pixel_y_c0 <= pixel_y_c0a;
        tile_index_c0 <= (tile_y_c0a * MAP_WIDTH) + tile_x_c0a;  // Now multiplication has full cycle
        vde_c0 <= vde_c0a;
        hsync_c0 <= hsync_c0a;
        vsync_c0 <= vsync_c0a;
        sprite_active_c0 <= sprite_active_c0a;
        sprite_pixel_x_c0 <= sprite_pixel_x_c0a;
        sprite_pixel_y_c0 <= sprite_pixel_y_c0a;
    end

    // Tilemap address (each 32-bit word stores 4 tile IDs)
    assign tilemap_addr = tile_index_c0[10:2];  // Divide by 4
    assign tilemap_en = 1'b1;

    // PIPELINE STAGE 1: Register tile positions and tilemap address selector
    logic [3:0] pixel_x_c1, pixel_y_c1;
    logic [5:0] tile_x_c1, tile_y_c1;
    logic [1:0] byte_sel_c1;  // Register byte selector to align with BRAM data
    logic vde_c1, hsync_c1, vsync_c1;
    logic sprite_active_c1;
    logic [3:0] sprite_pixel_x_c1, sprite_pixel_y_c1;

    always_ff @(posedge clk) begin
        pixel_x_c1 <= pixel_x_c0;
        pixel_y_c1 <= pixel_y_c0;
        tile_x_c1  <= tile_x_c0;
        tile_y_c1  <= tile_y_c0;
        byte_sel_c1 <= tile_index_c0[1:0];  // Register selector when address is sent
        vde_c1     <= vde_c0;
        hsync_c1 <= hsync_c0;
        vsync_c1 <= vsync_c0;
        sprite_active_c1 <= sprite_active_c0;
        sprite_pixel_x_c1 <= sprite_pixel_x_c0;
        sprite_pixel_y_c1 <= sprite_pixel_y_c0;
    end

    // PIPELINE STAGE 2: Register tilemap BRAM output and selector
    logic [3:0] pixel_x_c2, pixel_y_c2;
    logic [5:0] tile_x_c2, tile_y_c2;
    logic [1:0] byte_sel_c2;
    logic [31:0] tilemap_data_c2;  // Register BRAM output
    logic vde_c2, hsync_c2, vsync_c2;
    logic sprite_active_c2;
    logic [3:0] sprite_pixel_x_c2, sprite_pixel_y_c2;

    always_ff @(posedge clk) begin
        pixel_x_c2 <= pixel_x_c1;
        pixel_y_c2 <= pixel_y_c1;
        tile_x_c2  <= tile_x_c1;
        tile_y_c2  <= tile_y_c1;
        byte_sel_c2 <= byte_sel_c1;  // Register selector
        tilemap_data_c2 <= tilemap_data;  // Register BRAM output
        vde_c2     <= vde_c1;
        hsync_c2 <= hsync_c1;
        vsync_c2 <= vsync_c1;
        sprite_active_c2 <= sprite_active_c1;
        sprite_pixel_x_c2 <= sprite_pixel_x_c1;
        sprite_pixel_y_c2 <= sprite_pixel_y_c1;
    end

    // PIPELINE STAGE 3: Extract tile ID from registered data
    logic [7:0] tile_id_c3;
    logic [3:0] pixel_x_c3, pixel_y_c3;
    logic [5:0] tile_x_c3, tile_y_c3;
    logic vde_c3, hsync_c3, vsync_c3;
    logic sprite_active_c3;
    logic [3:0] sprite_pixel_x_c3, sprite_pixel_y_c3;

    always_ff @(posedge clk) begin
        pixel_x_c3 <= pixel_x_c2;
        pixel_y_c3 <= pixel_y_c2;
        tile_x_c3  <= tile_x_c2;
        tile_y_c3  <= tile_y_c2;
        vde_c3     <= vde_c2;
        hsync_c3 <= hsync_c2;
        vsync_c3 <= vsync_c2;
        sprite_active_c3 <= sprite_active_c2;
        sprite_pixel_x_c3 <= sprite_pixel_x_c2;
        sprite_pixel_y_c3 <= sprite_pixel_y_c2;

        // NOW both byte_sel_c2 and tilemap_data_c2 are stable registered values
        // Extract directly from c2 (no extra delay needed - this matches Lab7 pattern)
        case (byte_sel_c2)
            2'b00: tile_id_c3 <= tilemap_data_c2[7:0];
            2'b01: tile_id_c3 <= tilemap_data_c2[15:8];
            2'b10: tile_id_c3 <= tilemap_data_c2[23:16];
            2'b11: tile_id_c3 <= tilemap_data_c2[31:24];
        endcase
    end

    // PIPELINE STAGE 4: Calculate and REGISTER tile graphics address
    logic [7:0] tile_id_c4;
    logic [7:0] bg_tile_id_c4;  // NEW: Keep background tile_id for transparency
    logic [3:0] pixel_x_c4, pixel_y_c4;
    logic [5:0] tile_x_c4, tile_y_c4;
    logic [1:0] nibble_sel_c4;  // Register nibble selector
    logic [12:0] tilegfx_addr_c4;  // Register address for timing (13-bit for 8192 words)
    logic vde_c4, hsync_c4, vsync_c4;
    logic sprite_active_c4;
    logic [3:0] sprite_pixel_x_c4, sprite_pixel_y_c4;

    // Tile graphics memory layout:
    // Each tile is 16x16 pixels, 4-bit color per pixel
    // 4 pixels fit in one 32-bit word (16 bits used, 16 bits unused)
    // So each row = 4 words, total 16 rows = 64 words per tile
    // 92 tiles × 64 words = 5888 words total (requires 13 bits, using 8192 BRAM)

    // Combinational address calculation (will be registered in Stage 4)
    // Use direct calculation without intermediate variables to avoid bit width issues
    logic [12:0] tilegfx_addr_next;  // 13-bit to match BRAM IP
    logic [1:0] nibble_sel_next;

    // Multiplexed tile_id and pixel coordinates based on sprite activity
    logic [7:0] effective_tile_id;
    logic [3:0] effective_pixel_x, effective_pixel_y;

    always_comb begin
        // If sprite is active, use sprite tile and sprite pixel coordinates
        // Otherwise use background tile and background pixel coordinates
        if (sprite_active_c3) begin
            effective_tile_id = player_tile_id;
            effective_pixel_x = sprite_pixel_x_c3;
            effective_pixel_y = sprite_pixel_y_c3;
        end else begin
            effective_tile_id = tile_id_c3;
            effective_pixel_x = pixel_x_c3;
            effective_pixel_y = pixel_y_c3;
        end

        // Direct calculation: base + row_offset + col_offset
        // All operands explicitly 13-bit to match BRAM address width
        // base = tile_id * 64 = {tile_id[6:0], 6'b0}
        // row = pixel_y * 4 = {pixel_y[3:0], 2'b0}
        // col = pixel_x[3:2] (which word in the row: 0,1,2,3)
        tilegfx_addr_next = {effective_tile_id[6:0], 6'b000000} +
                           {7'b0000000, effective_pixel_y[3:0], 2'b00} +
                           {11'b00000000000, effective_pixel_x[3:2]};
        nibble_sel_next = effective_pixel_x[1:0];
    end

    // Register address to ensure sufficient setup time for BRAM
    // This provides the "wait state" needed for proper BRAM timing
    always_ff @(posedge clk) begin
        tile_id_c4 <= tile_id_c3;
        bg_tile_id_c4 <= tile_id_c3;  // NEW: Always keep background tile_id
        pixel_x_c4 <= pixel_x_c3;
        pixel_y_c4 <= pixel_y_c3;
        tile_x_c4  <= tile_x_c3;
        tile_y_c4  <= tile_y_c3;
        tilegfx_addr_c4 <= tilegfx_addr_next;  // Register address (CRITICAL FIX)
        nibble_sel_c4 <= nibble_sel_next;      // Register selector (now from multiplexed source)
        vde_c4     <= vde_c3;
        hsync_c4 <= hsync_c3;
        vsync_c4 <= vsync_c3;
        sprite_active_c4 <= sprite_active_c3;
        sprite_pixel_x_c4 <= sprite_pixel_x_c3;
        sprite_pixel_y_c4 <= sprite_pixel_y_c3;
    end

    // Output registered address to BRAM
    assign tilegfx_addr = tilegfx_addr_c4;
    assign tilegfx_en = 1'b1;

    // PIPELINE STAGE 5: Register tile graphics BRAM output
    logic [7:0] bg_tile_id_c5;  // NEW: Pass background tile_id
    logic [3:0] pixel_x_c5, pixel_y_c5;
    logic [5:0] tile_x_c5, tile_y_c5;
    logic [1:0] nibble_sel_c5;
    logic [31:0] tilegfx_data_c5;  // Register BRAM output
    logic vde_c5, hsync_c5, vsync_c5;
    logic sprite_active_c5;
    logic [3:0] sprite_pixel_x_c5, sprite_pixel_y_c5;

    always_ff @(posedge clk) begin
        bg_tile_id_c5 <= bg_tile_id_c4;  // NEW: Pass through
        pixel_x_c5 <= pixel_x_c4;
        pixel_y_c5 <= pixel_y_c4;
        tile_x_c5  <= tile_x_c4;
        tile_y_c5  <= tile_y_c4;
        nibble_sel_c5 <= nibble_sel_c4;  // Register selector
        tilegfx_data_c5 <= tilegfx_data;  // Register BRAM output
        vde_c5     <= vde_c4;
        hsync_c5 <= hsync_c4;
        vsync_c5 <= vsync_c4;
        sprite_active_c5 <= sprite_active_c4;
        sprite_pixel_x_c5 <= sprite_pixel_x_c4;
        sprite_pixel_y_c5 <= sprite_pixel_y_c4;
    end

    // PIPELINE STAGE 6: Extract pixel color from registered data
    logic [7:0] bg_tile_id_c6;  // NEW: Pass background tile_id
    logic sprite_active_c6;      // NEW: Pass sprite status
    logic [3:0] tile_color_c6;
    logic vde_c6, hsync_c6, vsync_c6;

    always_ff @(posedge clk) begin
        bg_tile_id_c6 <= bg_tile_id_c5;      // NEW: Pass through
        sprite_active_c6 <= sprite_active_c5; // NEW: Pass through
        vde_c6     <= vde_c5;
        hsync_c6 <= hsync_c5;
        vsync_c6 <= vsync_c5;

        // Extract pixel color from BRAM data
        // Note: When sprite is active (sprite_active_c3), tile_id_c3 is replaced
        // with player_tile_id, so tilegfx_data_c5 contains sprite graphics
        case (nibble_sel_c5)
            2'b00: tile_color_c6 <= tilegfx_data_c5[3:0];   // Pixel 0
            2'b01: tile_color_c6 <= tilegfx_data_c5[7:4];   // Pixel 1
            2'b10: tile_color_c6 <= tilegfx_data_c5[11:8];  // Pixel 2
            2'b11: tile_color_c6 <= tilegfx_data_c5[15:12]; // Pixel 3
        endcase
    end

    // PIPELINE STAGE 7: Palette lookup with transparency support
    // Sprite transparency: When sprite pixel color is 0 (transparent),
    // show background tile's representative color instead

    // Lookup table: background tile_id -> default color index
    function logic [3:0] get_bg_color(input logic [7:0] tile_id);
        case (tile_id)
            8'd0: get_bg_color = 4'd11;  // TILE_GRASS -> Medium Green
            8'd1: get_bg_color = 4'd7;   // TILE_PATH -> Light Gray
            8'd2: get_bg_color = 4'd4;   // TILE_BRICK -> Brick Red
            8'd3: get_bg_color = 4'd12;  // TILE_WATER -> Blue
            8'd4: get_bg_color = 4'd10;  // TILE_TREE -> Dark Green
            8'd5: get_bg_color = 4'd13;  // TILE_FLOWER -> Yellow/Gold
            default: get_bg_color = 4'd11; // Default to grass green
        endcase
    endfunction

    logic [3:0] final_color;
    always_comb begin
        if (sprite_active_c6 && (tile_color_c6 == 4'h0)) begin
            // Sprite pixel is transparent (color 0), show background color
            final_color = get_bg_color(bg_tile_id_c6);
        end else begin
            // Normal case: show sprite or background tile color
            final_color = tile_color_c6;
        end
    end

    // Palette lookup - Convert 4-bit index to 12-bit RGB
    logic [11:0] palette_rgb [16];

    // Unpack palette registers into 16 colors
    always_comb begin
        for (int i = 0; i < 8; i++) begin
            palette_rgb[i*2]   = palette_data[i][11:0];   // Low color
            palette_rgb[i*2+1] = palette_data[i][27:16];  // High color
        end
    end

    logic [11:0] selected_rgb;
    assign selected_rgb = palette_rgb[final_color];

    // Final RGB output
    always_ff @(posedge clk) begin
        if (~vde_c6) begin  // Use vde_c6 now
            red   <= 4'h0;
            green <= 4'h0;
            blue  <= 4'h0;
        end else begin
            red   <= selected_rgb[11:8];
            green <= selected_rgb[7:4];
            blue  <= selected_rgb[3:0];
        end
        
        // Output delayed sync signals to match RGB latency
        hsync_out <= hsync_c6;
        vsync_out <= vsync_c6;
        vde_out   <= vde_c6;
    end

endmodule
