#ifndef GAME_CONTROLLER_H
#define GAME_CONTROLLER_H

/****************** Include Files ********************/
#include "xil_types.h"
#include "xstatus.h"
#include "xparameters.h"

//=======================================================================
// CONSTANTS
//=======================================================================
#define TILE_SIZE 16
#define MAP_WIDTH 40
#define MAP_HEIGHT 30
#define SCREEN_WIDTH 640
#define SCREEN_HEIGHT 480

// Tile IDs (must match txt_to_coe.py mapping!)
// Small tiles (0-11)
#define TILE_GRASS           0
#define TILE_PATH            1
#define TILE_BRICK           2
#define TILE_WATER           3
#define TILE_TREE            4
#define TILE_FLOWER          5
#define TILE_TREASURE_CLOSE  6
#define TILE_TREASURE_OPEN   7
#define TILE_PLAYER_DOWN     8
#define TILE_PLAYER_UP       9
#define TILE_PLAYER_LEFT     10
#define TILE_PLAYER_RIGHT    11

// Building tiles (12-91)
// ECEB Building (12-43): 8 tiles wide × 4 tiles tall
#define TILE_ECEB_BASE       12
#define ECEB_WIDTH           8
#define ECEB_HEIGHT          4
// Helper macro to get ECEB tile at position (x, y) where x=0-7, y=0-3
#define TILE_ECEB(x, y)      (TILE_ECEB_BASE + (y) * ECEB_WIDTH + (x))

// Alma Mater (44-59): 4 tiles wide × 4 tiles tall
#define TILE_ALMA_BASE       44
#define ALMA_WIDTH           4
#define ALMA_HEIGHT          4
#define TILE_ALMA(x, y)      (TILE_ALMA_BASE + (y) * ALMA_WIDTH + (x))

// Main Quad (60-91): 8 tiles wide × 4 tiles tall
#define TILE_QUAD_BASE       60
#define QUAD_WIDTH           8
#define QUAD_HEIGHT          4
#define TILE_QUAD(x, y)      (TILE_QUAD_BASE + (y) * QUAD_WIDTH + (x))

// Aliases for compatibility
#define TILE_ROAD      TILE_PATH      // Path is the walkable tile
#define TILE_TREASURE  TILE_TREASURE_CLOSE
#define TILE_PLAYER    TILE_PLAYER_DOWN  // Default player sprite

// Color palette indices
#define COLOR_BLACK         0
#define COLOR_BLUE          1
#define COLOR_GREEN         2
#define COLOR_CYAN          3
#define COLOR_RED           4
#define COLOR_MAGENTA       5
#define COLOR_BROWN         6
#define COLOR_LIGHT_GRAY    7
#define COLOR_DARK_GRAY     8
#define COLOR_LIGHT_BLUE    9
#define COLOR_LIGHT_GREEN   10
#define COLOR_LIGHT_CYAN    11
#define COLOR_LIGHT_RED     12
#define COLOR_LIGHT_MAGENTA 13
#define COLOR_YELLOW        14
#define COLOR_WHITE         15

//=======================================================================
// MEMORY MAP STRUCTURE
//=======================================================================
struct GAME_CTRL_STRUCT {
    uint32_t TILEMAP[1200];      // 0x0000 - 0x12FF: Tile map data
    uint32_t RESERVED[848];      // 0x1300 - 0x1FFF: Reserved
    uint32_t PLAYER_X;           // 0x2000: Player X position (10-bit)
    uint32_t PLAYER_Y;           // 0x2004: Player Y position (10-bit)
    uint32_t PLAYER_CTRL;        // 0x2008: [8]=enable, [7:0]=tile_id
    uint32_t RESERVED2;          // 0x200C: Reserved
    uint32_t PALETTE[8];         // 0x2010-0x202F: Color palette
    uint32_t FRAME_COUNT;        // 0x2030: Frame counter (read-only)
};

// Base address - you may need to adjust this based on your Vivado design
#ifndef XPAR_GAME_GRAPHICS_CONTROLLER_0_S00_AXI_BASEADDR
#define XPAR_GAME_GRAPHICS_CONTROLLER_0_S00_AXI_BASEADDR 0x44A00000
#endif

static volatile struct GAME_CTRL_STRUCT* game_ctrl =
    (struct GAME_CTRL_STRUCT*)XPAR_GAME_GRAPHICS_CONTROLLER_0_S00_AXI_BASEADDR;

//=======================================================================
// FUNCTION PROTOTYPES
//=======================================================================

/**
 * Set player position
 * @param x X coordinate in pixels (0-639)
 * @param y Y coordinate in pixels (0-479)
 */
static inline void setPlayerPos(uint16_t x, uint16_t y) {
    game_ctrl->PLAYER_X = x;
    game_ctrl->PLAYER_Y = y;
}

/**
 * Get player position
 */
static inline void getPlayerPos(uint16_t* x, uint16_t* y) {
    *x = game_ctrl->PLAYER_X & 0x3FF;  // 10 bits
    *y = game_ctrl->PLAYER_Y & 0x3FF;
}

/**
 * Enable/disable player sprite
 */
static inline void setPlayerEnable(uint8_t enable) {
    if (enable)
        game_ctrl->PLAYER_CTRL |= (1 << 8);
    else
        game_ctrl->PLAYER_CTRL &= ~(1 << 8);
}

/**
 * Set player sprite tile ID
 */
static inline void setPlayerTile(uint8_t tile_id) {
    game_ctrl->PLAYER_CTRL = (game_ctrl->PLAYER_CTRL & 0xFF00) | tile_id;
}

/**
 * Set a tile in the tilemap
 * @param tile_x Tile X coordinate (0-39)
 * @param tile_y Tile Y coordinate (0-29)
 * @param tile_id Tile ID (0-255)
 */
static inline void setTile(uint8_t tile_x, uint8_t tile_y, uint8_t tile_id) {
    if (tile_x >= MAP_WIDTH || tile_y >= MAP_HEIGHT) return;

    uint16_t tile_index = tile_y * MAP_WIDTH + tile_x;
    uint16_t word_index = tile_index / 4;
    uint8_t byte_offset = tile_index % 4;

    uint32_t word = game_ctrl->TILEMAP[word_index];
    uint32_t mask = ~(0xFF << (byte_offset * 8));
    word = (word & mask) | (tile_id << (byte_offset * 8));
    game_ctrl->TILEMAP[word_index] = word;
}

/**
 * Get a tile from the tilemap
 */
static inline uint8_t getTile(uint8_t tile_x, uint8_t tile_y) {
    if (tile_x >= MAP_WIDTH || tile_y >= MAP_HEIGHT) return 0;

    uint16_t tile_index = tile_y * MAP_WIDTH + tile_x;
    uint16_t word_index = tile_index / 4;
    uint8_t byte_offset = tile_index % 4;

    uint32_t word = game_ctrl->TILEMAP[word_index];
    return (word >> (byte_offset * 8)) & 0xFF;
}

/**
 * Clear the entire tilemap
 */
static inline void clearTilemap(uint8_t tile_id) {
    uint32_t packed = (tile_id << 24) | (tile_id << 16) | (tile_id << 8) | tile_id;
    for (int i = 0; i < 1200; i++) {
        game_ctrl->TILEMAP[i] = packed;
    }
}

/**
 * Set palette color
 * @param index Color index (0-15)
 * @param r Red (0-15)
 * @param g Green (0-15)
 * @param b Blue (0-15)
 */
static inline void setPaletteColor(uint8_t index, uint8_t r, uint8_t g, uint8_t b) {
    if (index > 15) return;

    uint32_t rgb = ((r & 0xF) << 8) | ((g & 0xF) << 4) | (b & 0xF);
    uint8_t word_index = index / 2;
    uint8_t is_high = index % 2;

    if (is_high) {
        game_ctrl->PALETTE[word_index] =
            (game_ctrl->PALETTE[word_index] & 0x0000FFFF) | (rgb << 16);
    } else {
        game_ctrl->PALETTE[word_index] =
            (game_ctrl->PALETTE[word_index] & 0xFFFF0000) | rgb;
    }
}

/**
 * Wait for N frames
 */
static inline void waitFrames(uint32_t frames) {
    uint32_t start_frame = game_ctrl->FRAME_COUNT;
    while (game_ctrl->FRAME_COUNT < start_frame + frames) {
        // Busy wait
    }
}

/**
 * Get current frame count
 */
static inline uint32_t getFrameCount() {
    return game_ctrl->FRAME_COUNT;
}

/**
 * Convert pixel coordinates to tile coordinates
 */
static inline void pixelToTile(uint16_t pixel_x, uint16_t pixel_y,
                               uint8_t* tile_x, uint8_t* tile_y) {
    *tile_x = pixel_x / TILE_SIZE;
    *tile_y = pixel_y / TILE_SIZE;
}

/**
 * Convert tile coordinates to pixel coordinates (top-left corner)
 */
static inline void tileToPixel(uint8_t tile_x, uint8_t tile_y,
                               uint16_t* pixel_x, uint16_t* pixel_y) {
    *pixel_x = tile_x * TILE_SIZE;
    *pixel_y = tile_y * TILE_SIZE;
}

/**
 * Check if a tile position is walkable (not a wall)
 * This is a placeholder - you should customize based on your tile IDs
 */
static inline uint8_t isTileWalkable(uint8_t tile_id) {
    // Customize this based on your game design
    switch(tile_id) {
        case TILE_GRASS:
        case TILE_PATH:
        case TILE_TREASURE_CLOSE:
        case TILE_TREASURE_OPEN:
        case TILE_FLOWER:
            return 1;  // Walkable
        case TILE_BRICK:
        case TILE_WATER:
        case TILE_TREE:
            return 0;  // Not walkable
        default:
            return 1;  // Default to walkable
    }
}

/**
 * Initialize the game controller with default settings
 */
void initGameController();

/**
 * Load a test map (simple room for testing)
 */
void loadTestMap();

/**
 * Main game loop
 */
void gameLoop();

#endif // GAME_CONTROLLER_H
