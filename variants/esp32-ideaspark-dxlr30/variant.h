#pragma once

// --- SPI bus (VSPI - DO NOT TOUCH - matches working LoRa config) ---
#define PIN_SPI_SCK         5
#define PIN_SPI_MISO        19
#define PIN_SPI_MOSI        27

// --- LoRa: SX1262 (DX-LR30) ---
#define SX126X_CS           18
#define SX126X_RESET        14
#define SX126X_DIO1         26
#define SX126X_BUSY         32
#define SX126X_DIO2_AS_RF_SWITCH true


// --- Display: ST7789 1.14" IPS (IdeaSpark hardwired PCB) ---
#define ST7789_CS           15
#define ST7789_RS           2
#define ST7789_RESET        4
#define ST7789_BL           32
#define ST7789_SCK          18
#define ST7789_SDA          23
#define ST7789_MISO         19
#define ST7789_SPI_HOST     (spi_host_device_t)1
#define SPI_FREQUENCY       40000000
#define SPI_READ_FREQUENCY  16000000
#define ST7789_BUSY         -1
#define SPI_3_WIRE          0
#define TFT_HEIGHT          240
#define TFT_WIDTH           135
#define TFT_OFFSET_X        52
#define TFT_OFFSET_Y        40
#define TFT_OFFSET_ROTATION 0
#define HAS_SCREEN          1
#define USE_TFTDISPLAY      1

// --- GPIO ---
#define BUTTON_PIN          0
#define LED_PIN             2
#define I2C_SDA             21
#define I2C_SCL             22
