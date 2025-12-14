/**
 * game_main.c
 * Main game logic for UIUC Treasure Hunt
 * Ziheng Qi & Haoru Li
 * Fall 2025
 */

#include <stdio.h>
#include <stdlib.h>  
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "game_controller.h"
#include "usb_keyboard.h"
#include "xgpio.h"


XGpio Gpio_keycode;  

// Game state machine
typedef enum {
    STATE_TITLE_SCREEN,   // Showing title screen, waiting for ENTER
    STATE_PLAYING,        // Playing the game
    STATE_GAME_WON        // Won, showing WIN message
} GameState;

static GameState game_state = STATE_TITLE_SCREEN;
static int score = 0;              
static int total_treasures = 3;    
static int game_won = 0;           

// Treasure locations 
typedef struct {
    uint8_t x;
    uint8_t y;
    uint8_t collected;  
    uint8_t revealed;   
    uint8_t fleeing;   
    uint32_t last_move_frame;  
} Treasure;

static Treasure treasures[10];  
static int last_hint_frame = 0;  

/**
 * Initialize the game 
 */
void initGameController() {
    xil_printf("Initializing game controller...\n\r");

    setPaletteColor(0, 0x0, 0x0, 0x0);  // #000000

    // Color index 1: Skin Tone (Player skin)
    setPaletteColor(1, 0xF, 0xD, 0xB);  // #FFDDBB

    // Color index 2: Medium Brown (Tree trunk, treasure chest)
    setPaletteColor(2, 0x8, 0x6, 0x4);  // #886644

    // Color index 3: Dark Brown (Shadows, tree dark parts)
    setPaletteColor(3, 0x6, 0x4, 0x2);  // #664422

    // Color index 4: Brick Red (ECEB walls, buildings)
    setPaletteColor(4, 0xC, 0x4, 0x2);  // #CC4422

    // Color index 5: Dark Red (Brick shadows)
    setPaletteColor(5, 0x8, 0x2, 0x2);  // #882222

    // Color index 6: Orange (Treasure accents)
    setPaletteColor(6, 0xF, 0x8, 0x2);  // #FF8822

    // Color index 7: Light Gray (Path highlights - reserved)
    setPaletteColor(7, 0xC, 0xC, 0xC);  // #CCCCCC

    // Color index 8: Medium Gray (Stone paths)
    setPaletteColor(8, 0x8, 0x8, 0x8);  // #888888

    // Color index 9: Dark Gray (Player hair, Alma Mater base)
    setPaletteColor(9, 0x6, 0x6, 0x6);  // #666666

    // Color index 10: Dark Green (Grass shadows, water deep)
    setPaletteColor(10, 0x2, 0x6, 0x3);  // #226633

    // Color index 11: Medium Green (Grass main color)
    setPaletteColor(11, 0x4, 0xA, 0x4);  // #44AA44

    // Color index 12: Blue (Water surface, player shirt)
    setPaletteColor(12, 0x5, 0x8, 0xC);  // #5588CC

    // Color index 13: Yellow/Gold (Treasure coins, highlights)
    setPaletteColor(13, 0xF, 0xC, 0x4);  // #FFCC44

    // Color index 14: Player sprite placeholder color (Yellow)
    setPaletteColor(14, 0xF, 0xF, 0x0);  // #FFFF00 Bright Yellow

    // Color index 15: White (Water highlights, eyes)
    setPaletteColor(15, 0xF, 0xF, 0xF);  // #FFFFFF

    // Initialize player sprite (will be enabled when game starts)
    setPlayerTile(TILE_PLAYER_DOWN);
    setPlayerPos(300, 220);  // Near center, on path
    setPlayerEnable(0);  // Disabled initially (title screen)

    xil_printf("Game controller initialized.\n\r");
    xil_printf("  Player sprite initialized at (300, 220)\n\r");
}

/**
 * Load UIUC campus map with buildings
 * Layout:
 * - Top-left: ECEB (8x4 tiles)
 * - Top-right: Water lake (~10x8 tiles)
 * - Bottom-left: Alma Mater (4x4 tiles)
 * - Bottom-right: Main Quad (8x4 tiles)
 * - Paths, trees, flowers fill the rest
 */
void loadTestMap() {
    xil_printf("Loading UIUC campus map...\n\r");

    // Fill entire map with grass first
    clearTilemap(TILE_GRASS);

    // ========== BRICK WALL BORDER (1 tile thick) ==========
    for (int x = 0; x < MAP_WIDTH; x++) {
        setTile(x, 0, TILE_BRICK);   // Top
        setTile(x, MAP_HEIGHT - 1, TILE_BRICK); // Bottom
    }
    for (int y = 0; y < MAP_HEIGHT; y++) {
        setTile(0, y, TILE_BRICK);   // Left
        setTile(MAP_WIDTH - 1, y, TILE_BRICK);  // Right
    }

    // ========== ECEB BUILDING (Top-Left: 8x4 tiles) ==========
    int eceb_x = 2, eceb_y = 2;  // Start position
    for (int ty = 0; ty < ECEB_HEIGHT; ty++) {
        for (int tx = 0; tx < ECEB_WIDTH; tx++) {
            setTile(eceb_x + tx, eceb_y + ty, TILE_ECEB(tx, ty));
        }
    }

    // ========== LAKE ISLAND (Top-Right) ==========
    // Water ring with grass island in center
    int lake_x = 27, lake_y = 2;
    int lake_w = 11, lake_h = 10;

    // Draw water border
    for (int ty = 0; ty < lake_h; ty++) {
        for (int tx = 0; tx < lake_w; tx++) {
            // Water ring (outer border + inner area)
            if (ty == 0 || ty == lake_h-1 || tx == 0 || tx == lake_w-1 ||
                ty == 1 || ty == lake_h-2 || tx == 1 || tx == lake_w-2) {
                setTile(lake_x + tx, lake_y + ty, TILE_WATER);
            }
        }
    }
    // Gap on left side for path entrance
    setTile(lake_x, lake_y + 4, TILE_GRASS);
    setTile(lake_x, lake_y + 5, TILE_GRASS);
    setTile(lake_x + 1, lake_y + 4, TILE_GRASS);
    setTile(lake_x + 1, lake_y + 5, TILE_GRASS);

    // ========== ALMA MATER (Bottom-Left: 4x4 tiles) - Moved to center ==========
    int alma_x = 6, alma_y = 19;  // Moved from corner to center-left
    for (int ty = 0; ty < ALMA_HEIGHT; ty++) {
        for (int tx = 0; tx < ALMA_WIDTH; tx++) {
            setTile(alma_x + tx, alma_y + ty, TILE_ALMA(tx, ty));
        }
    }

    // ========== MAIN QUAD (Bottom-Right: 8x4 tiles) - Moved to center ==========
    int quad_x = 25, quad_y = 19;  // Moved from corner to center-right
    for (int ty = 0; ty < QUAD_HEIGHT; ty++) {
        for (int tx = 0; tx < QUAD_WIDTH; tx++) {
            setTile(quad_x + tx, quad_y + ty, TILE_QUAD(tx, ty));
        }
    }

    // ========== MAIN PATHS (Cross pattern + connections) ==========
    // Main horizontal path (middle)
    for (int x = 1; x < 39; x++) {
        setTile(x, 13, TILE_PATH);
        setTile(x, 14, TILE_PATH);  // 2 tiles wide
    }

    // Main vertical path (middle)
    for (int y = 1; y < 29; y++) {
        setTile(18, y, TILE_PATH);
        setTile(19, y, TILE_PATH);  // 2 tiles wide
    }

    // Path to ECEB (smooth L-shape)
    for (int x = 6; x < 11; x++) {
        setTile(x, 7, TILE_PATH);
    }
    for (int y = 7; y < 14; y++) {
        setTile(10, y, TILE_PATH);
        setTile(11, y, TILE_PATH);
    }

    // Path to Lake Island (smooth curve)
    for (int x = 20; x < 27; x++) {
        setTile(x, 6, TILE_PATH);
        setTile(x, 7, TILE_PATH);
    }

    // Path to Alma Mater (smooth approach)
    for (int y = 15; y < 19; y++) {
        setTile(7, y, TILE_PATH);
        setTile(8, y, TILE_PATH);
    }

    // Path to Main Quad (connect to top-middle of building at x=28-29, y=19)
    // Horizontal path from main vertical (x=19) to building center (x=28-29)
    for (int x = 20; x < 29; x++) {
        setTile(x, 17, TILE_PATH);
        setTile(x, 18, TILE_PATH);
    }
    // Vertical path connecting to building top
    for (int y = 15; y < 19; y++) {
        setTile(28, y, TILE_PATH);
        setTile(29, y, TILE_PATH);
    }

    // ========== PATH INTO LAKE ISLAND ==========
    // Extend path from gap (27, 6-7) into island center
    setTile(28, 6, TILE_PATH);
    setTile(28, 7, TILE_PATH);
    setTile(29, 6, TILE_PATH);
    setTile(29, 7, TILE_PATH);

    // ========== DECORATIONS (Trees and Flowers) ==========
    // Around ECEB
    setTile(11, 3, TILE_TREE);
    setTile(12, 4, TILE_FLOWER);
    setTile(13, 3, TILE_TREE);

    // DENSE FLOWER RING AROUND ALMA MATER (6-9, 19-22)
    // Top row (y=18, just above building)
    setTile(5, 18, TILE_FLOWER);
    setTile(6, 18, TILE_FLOWER);
    // Skip 7-8 (path connection)
    setTile(9, 18, TILE_FLOWER);
    setTile(10, 18, TILE_FLOWER);

    // Bottom row (y=23, just below building)
    setTile(5, 23, TILE_FLOWER);
    setTile(6, 23, TILE_FLOWER);
    setTile(7, 23, TILE_FLOWER);
    setTile(8, 23, TILE_FLOWER);
    setTile(9, 23, TILE_FLOWER);
    setTile(10, 23, TILE_FLOWER);

    // Left column (x=5)
    setTile(5, 19, TILE_FLOWER);
    setTile(5, 20, TILE_FLOWER);
    setTile(5, 21, TILE_FLOWER);
    setTile(5, 22, TILE_FLOWER);

    // Right column (x=10)
    setTile(10, 19, TILE_FLOWER);
    setTile(10, 20, TILE_FLOWER);
    setTile(10, 21, TILE_FLOWER);
    setTile(10, 22, TILE_FLOWER);

    // DENSE TREE RING AROUND MAIN QUAD (25-32, 19-22)
    // Top row (y=18, just above building) - skip path at x=28-29
    setTile(24, 18, TILE_TREE);
    setTile(25, 18, TILE_TREE);
    setTile(26, 18, TILE_TREE);
    setTile(27, 18, TILE_TREE);
    // Skip 28-29 (path)
    setTile(30, 18, TILE_TREE);
    setTile(31, 18, TILE_TREE);
    setTile(32, 18, TILE_TREE);
    setTile(33, 18, TILE_TREE);

    // Bottom row (y=23, just below building)
    setTile(24, 23, TILE_TREE);
    setTile(25, 23, TILE_TREE);
    setTile(26, 23, TILE_TREE);
    setTile(27, 23, TILE_TREE);
    setTile(28, 23, TILE_TREE);
    setTile(29, 23, TILE_TREE);
    setTile(30, 23, TILE_TREE);
    setTile(31, 23, TILE_TREE);
    setTile(32, 23, TILE_TREE);
    setTile(33, 23, TILE_TREE);

    // Left column (x=24)
    setTile(24, 19, TILE_TREE);
    setTile(24, 20, TILE_TREE);
    setTile(24, 21, TILE_TREE);
    setTile(24, 22, TILE_TREE);

    // Right column (x=33)
    setTile(33, 19, TILE_TREE);
    setTile(33, 20, TILE_TREE);
    setTile(33, 21, TILE_TREE);
    setTile(33, 22, TILE_TREE);

    // DENSE DECORATIONS IN LAKE ISLAND (center area around 30-34, 4-9)
    // Skip path tiles at (28-29, 6-7)
    setTile(30, 4, TILE_FLOWER);
    setTile(31, 4, TILE_TREE);
    setTile(32, 4, TILE_FLOWER);
    setTile(33, 4, TILE_TREE);
    setTile(34, 4, TILE_FLOWER);

    setTile(30, 5, TILE_TREE);
    setTile(31, 5, TILE_FLOWER);
    setTile(32, 5, TILE_TREE);
    setTile(33, 5, TILE_FLOWER);
    setTile(34, 5, TILE_TREE);

    setTile(30, 6, TILE_FLOWER);
    setTile(31, 6, TILE_TREE);
    setTile(32, 6, TILE_FLOWER);
    setTile(33, 6, TILE_TREE);
    setTile(34, 6, TILE_FLOWER);

    setTile(30, 7, TILE_TREE);
    setTile(31, 7, TILE_FLOWER);
    setTile(32, 7, TILE_TREE);
    setTile(33, 7, TILE_FLOWER);
    setTile(34, 7, TILE_TREE);

    setTile(30, 8, TILE_FLOWER);
    setTile(31, 8, TILE_TREE);
    setTile(32, 8, TILE_FLOWER);
    setTile(33, 8, TILE_TREE);
    setTile(34, 8, TILE_FLOWER);

    setTile(30, 9, TILE_TREE);
    setTile(31, 9, TILE_FLOWER);
    setTile(32, 9, TILE_TREE);
    setTile(33, 9, TILE_FLOWER);
    setTile(34, 9, TILE_TREE);

    // Random scattered decorations in other areas
    setTile(14, 10, TILE_TREE);
    setTile(22, 9, TILE_FLOWER);
    setTile(15, 20, TILE_TREE);
    setTile(16, 25, TILE_FLOWER);

    // ========== TREASURES (3 treasures - randomly placed) ==========
    // Define candidate positions for treasure spawning
    // Can spawn inside buildings (ECEB, Alma, Main Quad) and on empty grass
    // Cannot spawn on paths, trees, or flowers
    typedef struct {
        uint8_t x;
        uint8_t y;
    } Position;

    Position treasure_candidates[] = {
        // ===== ECEB Building interior (8x4 = 32 positions) =====
        {2, 2}, {3, 2}, {4, 2}, {5, 2}, {6, 2}, {7, 2}, {8, 2}, {9, 2},
        {2, 3}, {3, 3}, {4, 3}, {5, 3}, {6, 3}, {7, 3}, {8, 3}, {9, 3},
        {2, 4}, {3, 4}, {4, 4}, {5, 4}, {6, 4}, {7, 4}, {8, 4}, {9, 4},
        {2, 5}, {3, 5}, {4, 5}, {5, 5}, {6, 5}, {7, 5}, {8, 5}, {9, 5},

        // ===== Alma Mater interior (4x4 = 16 positions) =====
        {6, 19}, {7, 19}, {8, 19}, {9, 19},
        {6, 20}, {7, 20}, {8, 20}, {9, 20},
        {6, 21}, {7, 21}, {8, 21}, {9, 21},
        {6, 22}, {7, 22}, {8, 22}, {9, 22},

        // ===== Main Quad interior (8x4 = 32 positions) =====
        {25, 19}, {26, 19}, {27, 19}, {28, 19}, {29, 19}, {30, 19}, {31, 19}, {32, 19},
        {25, 20}, {26, 20}, {27, 20}, {28, 20}, {29, 20}, {30, 20}, {31, 20}, {32, 20},
        {25, 21}, {26, 21}, {27, 21}, {28, 21}, {29, 21}, {30, 21}, {31, 21}, {32, 21},
        {25, 22}, {26, 22}, {27, 22}, {28, 22}, {29, 22}, {30, 22}, {31, 22}, {32, 22},

        // ===== Empty grass areas (no decorations, no paths) =====
        {12, 10}, {13, 10}, {14, 10}, {15, 11}, {16, 11}, {17, 11},
        {20, 10}, {21, 11}, {22, 11}, {23, 10}, {24, 10},
        {12, 15}, {13, 15}, {14, 15}, {15, 15}, {16, 15}, {17, 15},
        {20, 15}, {21, 15}, {22, 15}, {23, 15}, {24, 15},
        {12, 20}, {13, 20}, {14, 21}, {15, 21}, {16, 21}, {17, 21},
        {20, 21}, {21, 21}, {22, 21}, {23, 22}, {24, 22},
        {12, 25}, {13, 25}, {14, 25}, {15, 25}, {16, 26}, {17, 26}
    };

    int num_candidates = sizeof(treasure_candidates) / sizeof(Position);

    // Randomly select 3 unique treasure positions
    // Use frame counter as seed for randomness
    srand(getFrameCount());

    int selected[3] = {-1, -1, -1};  // Indices of selected positions

    for (int i = 0; i < total_treasures; i++) {
        int idx;
        int is_duplicate;

        // Keep generating random indices until we get a unique one
        do {
            idx = rand() % num_candidates;
            is_duplicate = 0;

            // Check if this index was already selected
            for (int j = 0; j < i; j++) {
                if (selected[j] == idx) {
                    is_duplicate = 1;
                    break;
                }
            }
        } while (is_duplicate);

        // Store the selected index
        selected[i] = idx;

        // Initialize treasure at selected position
        treasures[i].x = treasure_candidates[idx].x;
        treasures[i].y = treasure_candidates[idx].y;
        treasures[i].collected = 0;
        treasures[i].revealed = 0;
        treasures[i].fleeing = 0;  // Not fleeing initially
        treasures[i].last_move_frame = 0;  // No movement yet

        // Set tile to grass initially (hidden)
        setTile(treasures[i].x, treasures[i].y, TILE_GRASS);

        xil_printf("  Treasure %d placed at (%d, %d)\n\r",
                   i+1, treasures[i].x, treasures[i].y);
    }

    xil_printf("Campus map loaded!\n\r");
    xil_printf("  ECEB at (%d, %d) - 8x4 tiles\n\r", eceb_x, eceb_y);
    xil_printf("  Lake island at (%d, %d) - with path entrance\n\r", lake_x, lake_y);
    xil_printf("  Alma Mater at (%d, %d) - 4x4 tiles with flower ring\n\r", alma_x, alma_y);
    xil_printf("  Main Quad at (%d, %d) - 8x4 tiles with tree ring\n\r", quad_x, quad_y);
    xil_printf("  Dense decorations placed\n\r");
    xil_printf("  Treasures randomly placed (collect them all!)\n\r");
}

/**
 * Handle player movement based on keyboard input
 */
void handlePlayerMovement(uint32_t keycode) {
    uint16_t player_x, player_y;
    getPlayerPos(&player_x, &player_y);

    uint16_t new_x = player_x;
    uint16_t new_y = player_y;
    uint8_t new_tile_id = TILE_PLAYER_DOWN;  // Default direction

    int moved = 0;

    // Check keycodes (W=0x1A, A=0x04, S=0x16, D=0x07)
    if ((keycode & 0xFF) == 0x1A) {  // W - move up
        if (new_y >= 2) new_y -= 2;
        new_tile_id = TILE_PLAYER_UP;  // Face up
        moved = 1;
    }
    else if ((keycode & 0xFF) == 0x16) {  // S - move down
        if (new_y < SCREEN_HEIGHT - TILE_SIZE - 2) new_y += 2;
        new_tile_id = TILE_PLAYER_DOWN;  // Face down
        moved = 1;
    }
    else if ((keycode & 0xFF) == 0x04) {  // A - move left
        if (new_x >= 2) new_x -= 2;
        new_tile_id = TILE_PLAYER_LEFT;  // Face left
        moved = 1;
    }
    else if ((keycode & 0xFF) == 0x07) {  // D - move right
        if (new_x < SCREEN_WIDTH - TILE_SIZE - 2) new_x += 2;
        new_tile_id = TILE_PLAYER_RIGHT;  // Face right
        moved = 1;
    }

    if (moved) {
        // Update player sprite direction
        setPlayerTile(new_tile_id);

        // Check collision with tiles
        uint8_t tile_x, tile_y;
        pixelToTile(new_x + TILE_SIZE/2, new_y + TILE_SIZE/2, &tile_x, &tile_y);
        uint8_t tile_id = getTile(tile_x, tile_y);

        if (isTileWalkable(tile_id)) {
            setPlayerPos(new_x, new_y);

            // Check if player collected a treasure
            if (tile_id == TILE_TREASURE_CLOSE) {
                score++;  // Increment score
                xil_printf("Treasure collected! Score: %d/%d\n\r", score, total_treasures);
                setTile(tile_x, tile_y, TILE_TREASURE_OPEN);  // Open treasure

                // Mark treasure as collected in list
                for (int i = 0; i < total_treasures; i++) {
                    if (treasures[i].x == tile_x && treasures[i].y == tile_y) {
                        treasures[i].collected = 1;
                        break;
                    }
                }

                // Check win condition
                if (score >= total_treasures && !game_won) {
                    game_won = 1;
                    game_state = STATE_GAME_WON;  // Transition to win state

                    // Display WIN message on HDMI screen!
                    displayWinMessage();

                    xil_printf("\n\r========================================\n\r");
                    xil_printf("   CONGRATULATIONS! YOU WIN!\n\r");
                    xil_printf("   All treasures collected!\n\r");
                    xil_printf("   Press R to return to title screen\n\r");
                    xil_printf("========================================\n\r\n\r");
                }
            }
        }
    }
}

/**
 * Calculate and display proximity hint to nearest treasure
 */
void displayProximityHint() {
    if (game_won) return;  // No hints after winning

    uint16_t player_x, player_y;
    getPlayerPos(&player_x, &player_y);

    // Convert pixel position to tile position
    uint8_t player_tile_x = player_x / TILE_SIZE;
    uint8_t player_tile_y = player_y / TILE_SIZE;

    // Find nearest uncollected treasure
    int min_distance = 9999;
    int nearest_idx = -1;

    for (int i = 0; i < total_treasures; i++) {
        if (!treasures[i].collected) {
            // Calculate Manhattan distance
            int dx = (player_tile_x > treasures[i].x) ?
                     (player_tile_x - treasures[i].x) : (treasures[i].x - player_tile_x);
            int dy = (player_tile_y > treasures[i].y) ?
                     (player_tile_y - treasures[i].y) : (treasures[i].y - player_tile_y);
            int distance = dx + dy;

            if (distance < min_distance) {
                min_distance = distance;
                nearest_idx = i;
            }
        }
    }

    // Display hint based on distance
    if (nearest_idx >= 0) {
        if (min_distance <= 3) {
            xil_printf("[HINT] Very Close! Treasure nearby!\n\r");
        } else if (min_distance <= 8) {
            xil_printf("[HINT] Getting warmer... Keep exploring!\n\r");
        } else {
            xil_printf("[HINT] Far away. Explore more of the campus.\n\r");
        }
    }
}

/**
 * Check if player is near any hidden treasures and reveal them
 */
void revealNearbyTreasures() {
    if (game_won) return;

    uint16_t player_x, player_y;
    getPlayerPos(&player_x, &player_y);

    // Convert pixel position to tile position
    uint8_t player_tile_x = player_x / TILE_SIZE;
    uint8_t player_tile_y = player_y / TILE_SIZE;

    // Check all treasures
    for (int i = 0; i < total_treasures; i++) {
        if (!treasures[i].collected && !treasures[i].revealed) {
            // Calculate Manhattan distance
            int dx = (player_tile_x > treasures[i].x) ?
                     (player_tile_x - treasures[i].x) : (treasures[i].x - player_tile_x);
            int dy = (player_tile_y > treasures[i].y) ?
                     (player_tile_y - treasures[i].y) : (treasures[i].y - player_tile_y);
            int distance = dx + dy;

            // Reveal if player is within 2 tiles
            if (distance <= 2) {
                treasures[i].revealed = 1;
                setTile(treasures[i].x, treasures[i].y, TILE_TREASURE_CLOSE);
                xil_printf("[DISCOVERY] Treasure revealed at (%d, %d)!\n\r",
                           treasures[i].x, treasures[i].y);
            }
        }
    }
}

/**
 * Move fleeing treasure away from player
 * Called for the last treasure when player gets too close
 */
void moveFleeingTreasure(int idx) {
    if (!treasures[idx].fleeing) return;  // Not fleeing, don't move

    uint32_t current_frame = getFrameCount();

    // Move every 12 frames (much slower than player - about 5 moves per second at 60fps)
    if (current_frame - treasures[idx].last_move_frame < 12) {
        return;  // Not time to move yet
    }

    // Get player position
    uint16_t player_x, player_y;
    getPlayerPos(&player_x, &player_y);
    uint8_t player_tile_x = player_x / TILE_SIZE;
    uint8_t player_tile_y = player_y / TILE_SIZE;

    // Calculate direction away from player
    int8_t dx = 0, dy = 0;
    if (treasures[idx].x > player_tile_x) {
        dx = 1;  // Run right
    } else if (treasures[idx].x < player_tile_x) {
        dx = -1;  // Run left
    }

    if (treasures[idx].y > player_tile_y) {
        dy = 1;  // Run down
    } else if (treasures[idx].y < player_tile_y) {
        dy = -1;  // Run up
    }

    // Try to move (prioritize direction with greater distance)
    int abs_dx = (treasures[idx].x > player_tile_x) ?
                 (treasures[idx].x - player_tile_x) : (player_tile_x - treasures[idx].x);
    int abs_dy = (treasures[idx].y > player_tile_y) ?
                 (treasures[idx].y - player_tile_y) : (player_tile_y - treasures[idx].y);

    uint8_t new_x = treasures[idx].x;
    uint8_t new_y = treasures[idx].y;
    int moved = 0;

    // Try primary direction first (whichever has smaller distance, move in that direction)
    if (abs_dx < abs_dy && dy != 0) {
        // Try vertical first
        new_y = treasures[idx].y + dy;
        uint8_t tile = getTile(treasures[idx].x, new_y);
        if (isTileWalkable(tile) && tile != TILE_TREASURE_CLOSE && tile != TILE_TREASURE_OPEN) {
            moved = 1;
        } else {
            new_y = treasures[idx].y;  // Restore
        }
    }

    if (!moved && dx != 0) {
        // Try horizontal
        new_x = treasures[idx].x + dx;
        uint8_t tile = getTile(new_x, treasures[idx].y);
        if (isTileWalkable(tile) && tile != TILE_TREASURE_CLOSE && tile != TILE_TREASURE_OPEN) {
            new_y = treasures[idx].y;  // Make sure only one direction
            moved = 1;
        } else {
            new_x = treasures[idx].x;  // Restore
        }
    }

    if (!moved && dy != 0 && abs_dx >= abs_dy) {
        // Try vertical as fallback
        new_y = treasures[idx].y + dy;
        new_x = treasures[idx].x;
        uint8_t tile = getTile(new_x, new_y);
        if (isTileWalkable(tile) && tile != TILE_TREASURE_CLOSE && tile != TILE_TREASURE_OPEN) {
            moved = 1;
        } else {
            new_y = treasures[idx].y;  // Restore
        }
    }

    // If still can't move, try random direction
    if (!moved) {
        int8_t dirs[4][2] = {{0, -1}, {0, 1}, {-1, 0}, {1, 0}};  // up, down, left, right
        int start = rand() % 4;
        for (int i = 0; i < 4; i++) {
            int dir_idx = (start + i) % 4;
            new_x = treasures[idx].x + dirs[dir_idx][0];
            new_y = treasures[idx].y + dirs[dir_idx][1];
            uint8_t tile = getTile(new_x, new_y);
            if (isTileWalkable(tile) && tile != TILE_TREASURE_CLOSE && tile != TILE_TREASURE_OPEN) {
                moved = 1;
                break;
            }
        }
    }

    // Execute the move
    if (moved) {
        // Clear old position
        setTile(treasures[idx].x, treasures[idx].y, TILE_GRASS);

        // Update treasure position
        treasures[idx].x = new_x;
        treasures[idx].y = new_y;

        // Draw treasure at new position
        setTile(new_x, new_y, TILE_TREASURE_CLOSE);

        // Update last move frame
        treasures[idx].last_move_frame = current_frame;
    }
}

/**
 * Load title screen with TREASURE HUNT title and UIUC "I"
 */
void loadTitleScreen() {
    // Upper half: Water (y=0 to y=16) - extended down by 2 rows
    for (int y = 0; y < 17; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            setTile(x, y, TILE_WATER);
        }
    }

    // Lower half: Grass (y=17 to y=29) - shorter
    for (int y = 17; y < MAP_HEIGHT; y++) {
        for (int x = 0; x < MAP_WIDTH; x++) {
            setTile(x, y, TILE_GRASS);
        }
    }

    // ========== TITLE: TREASURE HUNT (分两行，增加高度) ==========
    // Line 1: "TREASURE" - Starting at x=3, y=2 (moved left for more space, taller)
    int line1_x = 3;
    int line1_y = 2;

    // T (3 wide, 5 tall)
    setTile(line1_x + 0, line1_y + 0, TILE_BRICK);
    setTile(line1_x + 1, line1_y + 0, TILE_BRICK);
    setTile(line1_x + 2, line1_y + 0, TILE_BRICK);
    setTile(line1_x + 1, line1_y + 1, TILE_BRICK);
    setTile(line1_x + 1, line1_y + 2, TILE_BRICK);
    setTile(line1_x + 1, line1_y + 3, TILE_BRICK);
    setTile(line1_x + 1, line1_y + 4, TILE_BRICK);

    // R (4 wide, 5 tall)
    int r_x = line1_x + 4;
    setTile(r_x + 0, line1_y + 0, TILE_BRICK);
    setTile(r_x + 1, line1_y + 0, TILE_BRICK);
    setTile(r_x + 2, line1_y + 0, TILE_BRICK);
    setTile(r_x + 0, line1_y + 1, TILE_BRICK);
    setTile(r_x + 2, line1_y + 1, TILE_BRICK);
    setTile(r_x + 0, line1_y + 2, TILE_BRICK);
    setTile(r_x + 1, line1_y + 2, TILE_BRICK);
    setTile(r_x + 2, line1_y + 2, TILE_BRICK);
    setTile(r_x + 0, line1_y + 3, TILE_BRICK);
    setTile(r_x + 2, line1_y + 3, TILE_BRICK);
    setTile(r_x + 0, line1_y + 4, TILE_BRICK);
    setTile(r_x + 3, line1_y + 4, TILE_BRICK);

    // E (3 wide, 5 tall)
    int e1_x = line1_x + 9;
    setTile(e1_x + 0, line1_y + 0, TILE_BRICK);
    setTile(e1_x + 1, line1_y + 0, TILE_BRICK);
    setTile(e1_x + 2, line1_y + 0, TILE_BRICK);
    setTile(e1_x + 0, line1_y + 1, TILE_BRICK);
    setTile(e1_x + 0, line1_y + 2, TILE_BRICK);
    setTile(e1_x + 1, line1_y + 2, TILE_BRICK);
    setTile(e1_x + 0, line1_y + 3, TILE_BRICK);
    setTile(e1_x + 0, line1_y + 4, TILE_BRICK);
    setTile(e1_x + 1, line1_y + 4, TILE_BRICK);
    setTile(e1_x + 2, line1_y + 4, TILE_BRICK);

    // A (4 wide, 5 tall)
    int a_x = line1_x + 13;
    setTile(a_x + 1, line1_y + 0, TILE_BRICK);
    setTile(a_x + 2, line1_y + 0, TILE_BRICK);
    setTile(a_x + 0, line1_y + 1, TILE_BRICK);
    setTile(a_x + 3, line1_y + 1, TILE_BRICK);
    setTile(a_x + 0, line1_y + 2, TILE_BRICK);
    setTile(a_x + 1, line1_y + 2, TILE_BRICK);
    setTile(a_x + 2, line1_y + 2, TILE_BRICK);
    setTile(a_x + 3, line1_y + 2, TILE_BRICK);
    setTile(a_x + 0, line1_y + 3, TILE_BRICK);
    setTile(a_x + 3, line1_y + 3, TILE_BRICK);
    setTile(a_x + 0, line1_y + 4, TILE_BRICK);
    setTile(a_x + 3, line1_y + 4, TILE_BRICK);

    // S (3 wide, 5 tall)
    int s_x = line1_x + 18;
    setTile(s_x + 0, line1_y + 0, TILE_BRICK);
    setTile(s_x + 1, line1_y + 0, TILE_BRICK);
    setTile(s_x + 2, line1_y + 0, TILE_BRICK);
    setTile(s_x + 0, line1_y + 1, TILE_BRICK);
    setTile(s_x + 0, line1_y + 2, TILE_BRICK);
    setTile(s_x + 1, line1_y + 2, TILE_BRICK);
    setTile(s_x + 2, line1_y + 2, TILE_BRICK);
    setTile(s_x + 2, line1_y + 3, TILE_BRICK);
    setTile(s_x + 0, line1_y + 4, TILE_BRICK);
    setTile(s_x + 1, line1_y + 4, TILE_BRICK);
    setTile(s_x + 2, line1_y + 4, TILE_BRICK);

    // U (3 wide, 5 tall)
    int u_x = line1_x + 22;
    setTile(u_x + 0, line1_y + 0, TILE_BRICK);
    setTile(u_x + 2, line1_y + 0, TILE_BRICK);
    setTile(u_x + 0, line1_y + 1, TILE_BRICK);
    setTile(u_x + 2, line1_y + 1, TILE_BRICK);
    setTile(u_x + 0, line1_y + 2, TILE_BRICK);
    setTile(u_x + 2, line1_y + 2, TILE_BRICK);
    setTile(u_x + 0, line1_y + 3, TILE_BRICK);
    setTile(u_x + 2, line1_y + 3, TILE_BRICK);
    setTile(u_x + 0, line1_y + 4, TILE_BRICK);
    setTile(u_x + 1, line1_y + 4, TILE_BRICK);
    setTile(u_x + 2, line1_y + 4, TILE_BRICK);

    // R (4 wide, 5 tall)
    int r2_x = line1_x + 26;
    setTile(r2_x + 0, line1_y + 0, TILE_BRICK);
    setTile(r2_x + 1, line1_y + 0, TILE_BRICK);
    setTile(r2_x + 2, line1_y + 0, TILE_BRICK);
    setTile(r2_x + 0, line1_y + 1, TILE_BRICK);
    setTile(r2_x + 2, line1_y + 1, TILE_BRICK);
    setTile(r2_x + 0, line1_y + 2, TILE_BRICK);
    setTile(r2_x + 1, line1_y + 2, TILE_BRICK);
    setTile(r2_x + 2, line1_y + 2, TILE_BRICK);
    setTile(r2_x + 0, line1_y + 3, TILE_BRICK);
    setTile(r2_x + 2, line1_y + 3, TILE_BRICK);
    setTile(r2_x + 0, line1_y + 4, TILE_BRICK);
    setTile(r2_x + 3, line1_y + 4, TILE_BRICK);

    // E (3 wide, 5 tall) - the missing E!
    int e2_x = line1_x + 31;
    setTile(e2_x + 0, line1_y + 0, TILE_BRICK);
    setTile(e2_x + 1, line1_y + 0, TILE_BRICK);
    setTile(e2_x + 2, line1_y + 0, TILE_BRICK);
    setTile(e2_x + 0, line1_y + 1, TILE_BRICK);
    setTile(e2_x + 0, line1_y + 2, TILE_BRICK);
    setTile(e2_x + 1, line1_y + 2, TILE_BRICK);
    setTile(e2_x + 0, line1_y + 3, TILE_BRICK);
    setTile(e2_x + 0, line1_y + 4, TILE_BRICK);
    setTile(e2_x + 1, line1_y + 4, TILE_BRICK);
    setTile(e2_x + 2, line1_y + 4, TILE_BRICK);

    // Line 2: "HUNT" - Starting at x=13, y=9 (increased height)
    int line2_x = 13;
    int line2_y = 9;

    // H (3 wide, 5 tall)
    setTile(line2_x + 0, line2_y + 0, TILE_BRICK);
    setTile(line2_x + 2, line2_y + 0, TILE_BRICK);
    setTile(line2_x + 0, line2_y + 1, TILE_BRICK);
    setTile(line2_x + 2, line2_y + 1, TILE_BRICK);
    setTile(line2_x + 0, line2_y + 2, TILE_BRICK);
    setTile(line2_x + 1, line2_y + 2, TILE_BRICK);
    setTile(line2_x + 2, line2_y + 2, TILE_BRICK);
    setTile(line2_x + 0, line2_y + 3, TILE_BRICK);
    setTile(line2_x + 2, line2_y + 3, TILE_BRICK);
    setTile(line2_x + 0, line2_y + 4, TILE_BRICK);
    setTile(line2_x + 2, line2_y + 4, TILE_BRICK);

    // U (3 wide, 5 tall)
    int u2_x = line2_x + 4;
    setTile(u2_x + 0, line2_y + 0, TILE_BRICK);
    setTile(u2_x + 2, line2_y + 0, TILE_BRICK);
    setTile(u2_x + 0, line2_y + 1, TILE_BRICK);
    setTile(u2_x + 2, line2_y + 1, TILE_BRICK);
    setTile(u2_x + 0, line2_y + 2, TILE_BRICK);
    setTile(u2_x + 2, line2_y + 2, TILE_BRICK);
    setTile(u2_x + 0, line2_y + 3, TILE_BRICK);
    setTile(u2_x + 2, line2_y + 3, TILE_BRICK);
    setTile(u2_x + 0, line2_y + 4, TILE_BRICK);
    setTile(u2_x + 1, line2_y + 4, TILE_BRICK);
    setTile(u2_x + 2, line2_y + 4, TILE_BRICK);

    // N (4 wide, 5 tall)
    int n_x = line2_x + 8;
    setTile(n_x + 0, line2_y + 0, TILE_BRICK);
    setTile(n_x + 3, line2_y + 0, TILE_BRICK);
    setTile(n_x + 0, line2_y + 1, TILE_BRICK);
    setTile(n_x + 1, line2_y + 1, TILE_BRICK);
    setTile(n_x + 3, line2_y + 1, TILE_BRICK);
    setTile(n_x + 0, line2_y + 2, TILE_BRICK);
    setTile(n_x + 2, line2_y + 2, TILE_BRICK);
    setTile(n_x + 3, line2_y + 2, TILE_BRICK);
    setTile(n_x + 0, line2_y + 3, TILE_BRICK);
    setTile(n_x + 2, line2_y + 3, TILE_BRICK);
    setTile(n_x + 3, line2_y + 3, TILE_BRICK);
    setTile(n_x + 0, line2_y + 4, TILE_BRICK);
    setTile(n_x + 3, line2_y + 4, TILE_BRICK);

    // T (3 wide, 5 tall)
    int t_x = line2_x + 13;
    setTile(t_x + 0, line2_y + 0, TILE_BRICK);
    setTile(t_x + 1, line2_y + 0, TILE_BRICK);
    setTile(t_x + 2, line2_y + 0, TILE_BRICK);
    setTile(t_x + 1, line2_y + 1, TILE_BRICK);
    setTile(t_x + 1, line2_y + 2, TILE_BRICK);
    setTile(t_x + 1, line2_y + 3, TILE_BRICK);
    setTile(t_x + 1, line2_y + 4, TILE_BRICK);

    // ========== Decorations at water-grass boundary ==========
    // Row of flowers at y=17 (first grass row, water-grass boundary)
    for (int x = 1; x < MAP_WIDTH - 1; x++) {
        setTile(x, 17, TILE_FLOWER);
    }

    // Row of trees at y=18 (below flowers)
    for (int x = 1; x < MAP_WIDTH - 1; x++) {
        setTile(x, 18, TILE_TREE);
    }

    // ========== ECEB Building in grass area (center-bottom) ==========
    int eceb_x = 16;  // Centered horizontally (40 tiles wide, 8-tile building, (40-8)/2 = 16)
    int eceb_y = 20;  // Near bottom (grass starts at y=17, flowers at 17, trees at 18, empty at 19)
    for (int ty = 0; ty < ECEB_HEIGHT; ty++) {
        for (int tx = 0; tx < ECEB_WIDTH; tx++) {
            setTile(eceb_x + tx, eceb_y + ty, TILE_ECEB(tx, ty));
        }
    }

    // ========== UIUC "I" in bottom right corner (adjusted) ==========
    // Big "I" at x=34-37, y=24-29 (6 tall, 4 wide)
    int i_x = 34;
    int i_y = 24;

    // Top bar
    setTile(i_x + 0, i_y + 0, TILE_BRICK);
    setTile(i_x + 1, i_y + 0, TILE_BRICK);
    setTile(i_x + 2, i_y + 0, TILE_BRICK);
    setTile(i_x + 3, i_y + 0, TILE_BRICK);

    // Middle column
    setTile(i_x + 1, i_y + 1, TILE_BRICK);
    setTile(i_x + 2, i_y + 1, TILE_BRICK);
    setTile(i_x + 1, i_y + 2, TILE_BRICK);
    setTile(i_x + 2, i_y + 2, TILE_BRICK);
    setTile(i_x + 1, i_y + 3, TILE_BRICK);
    setTile(i_x + 2, i_y + 3, TILE_BRICK);
    setTile(i_x + 1, i_y + 4, TILE_BRICK);
    setTile(i_x + 2, i_y + 4, TILE_BRICK);

    // Bottom bar
    setTile(i_x + 0, i_y + 5, TILE_BRICK);
    setTile(i_x + 1, i_y + 5, TILE_BRICK);
    setTile(i_x + 2, i_y + 5, TILE_BRICK);
    setTile(i_x + 3, i_y + 5, TILE_BRICK);

    // Hide player sprite on title screen
    setPlayerEnable(0);

    xil_printf("Title screen loaded! Press ENTER to start.\n\r");
    xil_printf("  Water (y=0-16), Flowers (y=17), Trees (y=18)\n\r");
    xil_printf("  ECEB Building (center), UIUC 'I' (bottom right)\n\r");
}

/**
 * Display WIN message on screen using brick tiles
 */
void displayWinMessage() {
    // Clear top area for WIN message (y=1 to y=5)
    for (int y = 1; y <= 5; y++) {
        for (int x = 1; x < MAP_WIDTH - 1; x++) {
            setTile(x, y, TILE_GRASS);  // Clear with grass
        }
    }

    // Draw WIN! using brick tiles (TILE_BRICK)
    // Starting position: x=10, y=2 (centered)
    int start_x = 10;
    int start_y = 2;

    // Letter W (5 tiles wide, 4 tiles tall)
    setTile(start_x + 0, start_y + 0, TILE_BRICK);
    setTile(start_x + 0, start_y + 1, TILE_BRICK);
    setTile(start_x + 0, start_y + 2, TILE_BRICK);
    setTile(start_x + 0, start_y + 3, TILE_BRICK);

    setTile(start_x + 1, start_y + 3, TILE_BRICK);

    setTile(start_x + 2, start_y + 1, TILE_BRICK);
    setTile(start_x + 2, start_y + 2, TILE_BRICK);
    setTile(start_x + 2, start_y + 3, TILE_BRICK);

    setTile(start_x + 3, start_y + 3, TILE_BRICK);

    setTile(start_x + 4, start_y + 0, TILE_BRICK);
    setTile(start_x + 4, start_y + 1, TILE_BRICK);
    setTile(start_x + 4, start_y + 2, TILE_BRICK);
    setTile(start_x + 4, start_y + 3, TILE_BRICK);

    // Letter I (3 tiles wide, 4 tiles tall)
    int i_x = start_x + 7;
    setTile(i_x + 0, start_y + 0, TILE_BRICK);
    setTile(i_x + 1, start_y + 0, TILE_BRICK);
    setTile(i_x + 2, start_y + 0, TILE_BRICK);

    setTile(i_x + 1, start_y + 1, TILE_BRICK);
    setTile(i_x + 1, start_y + 2, TILE_BRICK);

    setTile(i_x + 0, start_y + 3, TILE_BRICK);
    setTile(i_x + 1, start_y + 3, TILE_BRICK);
    setTile(i_x + 2, start_y + 3, TILE_BRICK);

    // Letter N (5 tiles wide, 4 tiles tall)
    int n_x = start_x + 12;
    setTile(n_x + 0, start_y + 0, TILE_BRICK);
    setTile(n_x + 0, start_y + 1, TILE_BRICK);
    setTile(n_x + 0, start_y + 2, TILE_BRICK);
    setTile(n_x + 0, start_y + 3, TILE_BRICK);

    setTile(n_x + 1, start_y + 1, TILE_BRICK);

    setTile(n_x + 2, start_y + 2, TILE_BRICK);

    setTile(n_x + 3, start_y + 3, TILE_BRICK);

    setTile(n_x + 4, start_y + 0, TILE_BRICK);
    setTile(n_x + 4, start_y + 1, TILE_BRICK);
    setTile(n_x + 4, start_y + 2, TILE_BRICK);
    setTile(n_x + 4, start_y + 3, TILE_BRICK);

    // Exclamation mark!
    int ex_x = start_x + 19;
    setTile(ex_x, start_y + 0, TILE_BRICK);
    setTile(ex_x, start_y + 1, TILE_BRICK);
    setTile(ex_x, start_y + 3, TILE_BRICK);

    xil_printf("WIN message displayed on screen!\n\r");
}

/**
 * Reset game and return to title screen
 */
void resetGame() {
    xil_printf("\n\r=== RETURNING TO TITLE SCREEN ===\n\r");

    // Reset game state
    score = 0;
    game_won = 0;
    game_state = STATE_TITLE_SCREEN;

    // Load title screen
    loadTitleScreen();

    xil_printf("Press ENTER to start a new game.\n\r\n\r");
}

/**
 * Main game loop
 */
void gameLoop() {
    xil_printf("\n\r=== Starting Game Loop ===\n\r");

    uint32_t last_frame = 0;
    uint32_t keycode = 0;

    while (1) {
        // Poll USB keyboard for new input
        pollUSBKeyboard();

        // Read keyboard input from GPIO
        keycode = XGpio_DiscreteRead(&Gpio_keycode, 1);

        // ========== STATE: TITLE SCREEN ==========
        if (game_state == STATE_TITLE_SCREEN) {
            // Check for ENTER key to start game (keycode 0x28)
            if ((keycode & 0xFF) == 0x28) {
                // Transition to playing state
                game_state = STATE_PLAYING;
                xil_printf("\n\r=== GAME STARTED ===\n\r");

                // Load game map (with randomized treasure positions)
                loadTestMap();

                // Reset player position to center
                setPlayerPos(300, 220);
                setPlayerTile(TILE_PLAYER_DOWN);

                // Enable player sprite
                setPlayerEnable(1);

                xil_printf("Controls: WASD to move, R to return to title screen\n\r");
                xil_printf("Collect all treasures!\n\r\n\r");
            }

            // Wait for next frame and skip game logic
            waitFrames(1);
            continue;
        }

        // ========== STATE: PLAYING or GAME_WON ==========
        // Check for R key (Return to title screen) - keycode 0x15
        if ((keycode & 0xFF) == 0x15) {
            resetGame();
            keycode = 0;  // Clear keycode to prevent repeated resets
            continue;
        }

        // Handle player movement (only in PLAYING state)
        if (game_state == STATE_PLAYING && keycode != 0) {
            handlePlayerMovement(keycode);
        }

        // Check for nearby treasures to reveal (only in PLAYING state)
        if (game_state == STATE_PLAYING) {
            revealNearbyTreasures();

            // ========== FLEEING TREASURE LOGIC ==========
            // Only trigger when player has collected 2 treasures (score >= 2)
            // This ensures we don't trigger on the first revealed treasure
            int last_treasure_idx = -1;

            if (score >= total_treasures - 1) {  // If collected 2 out of 3 treasures
                // Find the last uncollected treasure
                for (int i = 0; i < total_treasures; i++) {
                    if (!treasures[i].collected && treasures[i].revealed) {
                        last_treasure_idx = i;
                        break;  // Found the last one
                    }
                }
            }

            // If we found the last treasure, check if player is close
            if (last_treasure_idx >= 0) {
                uint16_t player_x, player_y;
                getPlayerPos(&player_x, &player_y);
                uint8_t player_tile_x = player_x / TILE_SIZE;
                uint8_t player_tile_y = player_y / TILE_SIZE;

                // Calculate distance to last treasure
                int dx = (player_tile_x > treasures[last_treasure_idx].x) ?
                         (player_tile_x - treasures[last_treasure_idx].x) :
                         (treasures[last_treasure_idx].x - player_tile_x);
                int dy = (player_tile_y > treasures[last_treasure_idx].y) ?
                         (player_tile_y - treasures[last_treasure_idx].y) :
                         (treasures[last_treasure_idx].y - player_tile_y);
                int distance = dx + dy;

                // Trigger fleeing if within 3 tiles
                if (distance <= 3 && !treasures[last_treasure_idx].fleeing) {
                    treasures[last_treasure_idx].fleeing = 1;
                    treasures[last_treasure_idx].last_move_frame = getFrameCount();
                    xil_printf("\n\r[ALERT] The last treasure is trying to escape!\n\r");
                    xil_printf("[ALERT] Chase it down!\n\r\n\r");
                }

                // Move the fleeing treasure
                if (treasures[last_treasure_idx].fleeing) {
                    moveFleeingTreasure(last_treasure_idx);
                }
            }
        }

        // Wait for next frame
        waitFrames(1);

        // Display status and hints less frequently (only in PLAYING state)
        if (game_state == STATE_PLAYING) {
            uint32_t current_frame = getFrameCount();

            // Print score every 30 seconds (1800 frames at 60fps)
            if (current_frame - last_frame >= 1800) {
                xil_printf("[STATUS] Score: %d/%d treasures collected\n\r", score, total_treasures);
                last_frame = current_frame;
            }

            // Display proximity hint every 5 seconds (300 frames)
            if (current_frame - last_hint_frame >= 300) {
                displayProximityHint();
                last_hint_frame = current_frame;
            }
        }
    }
}

/**
 * Main function
 */
int main() {
    xil_printf("\n\n=== UIUC Treasure Hunt Game ===\n\r");
    xil_printf("by Ziheng Qi & Haoru Li\n\r");
    xil_printf("ECE 385 Final Project\n\r\n\r");

    init_platform();

    // Initialize keyboard GPIO FIRST (before USB driver)
    // USB driver will write keycodes to this GPIO, game will read from it
    xil_printf("Initializing keycode GPIO...\n\r");
    int status = XGpio_Initialize(&Gpio_keycode, XPAR_GPIO_USB_KEYCODE_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: Failed to initialize keycode GPIO\n\r");
        return -1;
    }
    // Set as OUTPUT to allow USB driver to write, we can still read current value
    XGpio_SetDataDirection(&Gpio_keycode, 1, 0x00000000);  // Output (USB writes)
    XGpio_SetDataDirection(&Gpio_keycode, 2, 0x00000000);  // Output (USB writes)

    // Initialize USB keyboard hardware and driver
    if (initUSBKeyboard() != 0) {
        xil_printf("ERROR: Failed to initialize USB keyboard\n\r");
        return -1;
    }

    // Initialize game controller (palette, sprite position)
    initGameController();

    // Load title screen (game starts here)
    loadTitleScreen();

    xil_printf("\n\rWaiting for USB keyboard connection...\n\r");

    // Run game loop
    gameLoop();

    cleanup_platform();
    return 0;
}
