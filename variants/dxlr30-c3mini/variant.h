#pragma once

// --- ESP32-C3 Super Mini + DX-LR30 (SX1262) ---

// Button
#define BUTTON_PIN      9   // BOOT button
#define LED_PIN         8   // onboard blue LED

// LoRa: DX-LR30 (SX1262)
#define USE_SX1262
#define LORA_SCK        4
#define LORA_MISO       5
#define LORA_MOSI       6
#define LORA_CS         7
#define LORA_DIO1       3
#define LORA_BUSY       2
#define LORA_RESET      10

#define SX126X_CS       LORA_CS
#define SX126X_DIO1     LORA_DIO1
#define SX126X_BUSY     LORA_BUSY
#define SX126X_RESET    LORA_RESET
#define SX126X_DIO2_AS_RF_SWITCH true

// No screen, no I2C
#define I2C_SDA         -1
#define I2C_SCL         -1
