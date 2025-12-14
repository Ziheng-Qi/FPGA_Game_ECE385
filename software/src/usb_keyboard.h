/**
 * usb_keyboard.h
 * USB Keyboard driver integration for UIUC Treasure Hunt
 * Based on Lab 6 USB implementation
 * Ziheng Qi & Haoru Li
 * Fall 2025
 */

#ifndef USB_KEYBOARD_H
#define USB_KEYBOARD_H

#include "GenericMacros.h"
#include "GenericTypeDefs.h"
#include "HID.h"

/**
 * Initialize USB keyboard hardware
 * Returns 0 on success, -1 on failure
 */
int initUSBKeyboard(void);

/**
 * Poll USB keyboard for new input
 * Updates the GPIO keycode registers if keyboard is connected
 * Returns 0 on success, -1 on error
 */
int pollUSBKeyboard(void);

/**
 * Get USB device status
 * Returns 1 if keyboard is connected, 0 otherwise
 */
int isUSBKeyboardConnected(void);

#endif // USB_KEYBOARD_H
