#pragma once


// SPI (VSPI - standard ESP32 hardware bus)
// SPI (DO NOT TOUCH)
#define PIN_SPI_SCK   5
#define PIN_SPI_MISO  19
#define PIN_SPI_MOSI  27

// SX1262 (MUST MATCH SPI NSS)
#define SX126X_CS     18   // ✅ FIXED
#define SX126X_RESET  14
#define SX126X_DIO1   26
#define SX126X_BUSY   32

// peripherals
#define BUTTON_PIN      0
#define LED_PIN         2
#define I2C_SDA         21
#define I2C_SCL         22
