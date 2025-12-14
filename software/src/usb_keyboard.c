/**
 * usb_keyboard.c
 * USB Keyboard driver implementation
 * Based on Lab 6 USB implementation, adapted for game use
 * Ziheng Qi & Haoru Li
 * Fall 2025
 */

#include "usb_keyboard.h"
#include "MAX3421E.h"
#include "USB.h"
#include "usb_ch9.h"
#include "transfer.h"
#include "xparameters.h"
#include "xgpio.h"
#include "xil_printf.h"

// GLOBALS
extern HID_DEVICE hid_device;

// Use extern to reference GPIO initialized in game_main.c
// This avoids duplicate initialization which causes conflicts
extern XGpio Gpio_keycode;

static BYTE addr = 1;  // Hard-wired USB address
static BYTE device_type = 0xFF;  // 1 = keyboard, 2 = mouse
static BYTE usb_initialized = 0;
static BYTE usb_running = 0;

// INTERNAL FUNCTIONS

/**
 * Get USB device type and report capabilities
 */
static BYTE getDriverAndReport() {
    BYTE i;
    BYTE rcode;
    BYTE device = 0xFF;
    BYTE tmpbyte;
    DEV_RECORD* tpl_ptr;

    xil_printf("USB reached RUNNING state\n\r");

    for (i = 1; i < USB_NUMDEVICES; i++) {
        tpl_ptr = GetDevtable(i);
        if (tpl_ptr->epinfo != NULL) {
            const char* devclasses[] = {
                "Uninitialized", "HID Keyboard", "HID Mouse", "Mass Storage"
            };
            xil_printf("  Device %d: %s\n\r", i, devclasses[tpl_ptr->devclass]);
            device = tpl_ptr->devclass;
        }
    }

    // Query rate and protocol
    rcode = XferGetIdle(addr, 0, hid_device.interface, 0, &tmpbyte);
    if (rcode) {
        xil_printf("  GetIdle Error: 0x%x\n\r", rcode);
    } else {
        xil_printf("  Update rate: 0x%x\n\r", tmpbyte);
    }

    rcode = XferGetProto(addr, 0, hid_device.interface, &tmpbyte);
    if (rcode) {
        xil_printf("  GetProto Error: 0x%x\n\r", rcode);
    } else {
        xil_printf("  Protocol: %d\n\r", tmpbyte);
    }

    return device;
}

/**
 * Write keycode to GPIO register
 */
static void writeKeycode(u32 data, unsigned channel) {
    XGpio_DiscreteWrite(&Gpio_keycode, channel, data);
}

// PUBLIC API

/**
 * Initialize USB keyboard hardware
 * Note: Gpio_keycode must be initialized by caller (game_main.c)
 */
int initUSBKeyboard(void) {
    xil_printf("Initializing USB keyboard driver...\n\r");

    // Initialize MAX3421E USB host controller
    xil_printf("Initializing MAX3421E...\n\r");
    MAX3421E_init();

    // Initialize USB stack
    xil_printf("Initializing USB stack...\n\r");
    USB_init();

    usb_initialized = 1;
    xil_printf("USB keyboard driver initialized\n\r");
    return 0;
}

/**
 * Poll USB keyboard for input
 */
int pollUSBKeyboard(void) {
    if (!usb_initialized) {
        return -1;
    }

    // Run USB task state machine
    MAX3421E_Task();
    USB_Task();

    // Check USB state
    BYTE usb_state = GetUsbTaskState();

    if (usb_state == USB_STATE_RUNNING) {
        if (!usb_running) {
            usb_running = 1;
            device_type = getDriverAndReport();
        }

        // If keyboard detected, poll for keycodes
        if (device_type == 1) {
            BOOT_KBD_REPORT kbdbuf;
            BYTE rcode = kbdPoll(&kbdbuf);

            if (rcode == hrNAK) {
                // NAK means no new data, this is normal
                return 0;
            } else if (rcode) {
                // Error occurred
                xil_printf("Keyboard poll error: 0x%x\n\r", rcode);
                return -1;
            }

            // New keycode data received
            // Pack keycodes into GPIO registers (matching Lab 6 format)
            u32 keycode_ch1 = kbdbuf.keycode[0] + (kbdbuf.keycode[1] << 8) +
                              (kbdbuf.keycode[2] << 16) + (kbdbuf.keycode[3] << 24);
            u32 keycode_ch2 = kbdbuf.keycode[4] + (kbdbuf.keycode[5] << 8);

            writeKeycode(keycode_ch1, 1);
            writeKeycode(keycode_ch2, 2);

            return 0;
        }
    } else if (usb_state == USB_STATE_ERROR) {
        if (usb_running) {
            xil_printf("USB Error State - reinitializing...\n\r");
            usb_running = 0;
            MAX3421E_init();
            USB_init();
        }
        return -1;
    } else {
        // Not in running state yet
        if (usb_running) {
            // Previously running, reset USB
            usb_running = 0;
            MAX3421E_init();
            USB_init();
        }
        return 0;
    }

    return 0;
}

/**
 * Check if USB keyboard is connected
 */
int isUSBKeyboardConnected(void) {
    return (usb_running && device_type == 1);
}
