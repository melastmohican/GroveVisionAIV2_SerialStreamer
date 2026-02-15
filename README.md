# Grove Vision AI V2 Serial Streamer

A high-performance video streaming system that captures images from the **Grove Vision AI V2** module and streams them in real-time to a PC via an **XIAO ESP32C3** (or similar microcontroller).

Includes both **Processing** and **Python** desktop client implementations.

---

## 🛠️ Hardware Requirements

* **Camera Module**: [Seeed Studio Grove Vision AI V2](https://www.seeedstudio.com/Grove-Vision-AI-Module-V2-p-5851.html)
* **Microcontroller**: [Seeed Studio XIAO ESP32C3](https://www.seeedstudio.com/Seeed-XIAO-ESP32C3-p-5434.html)
* **Connection**: The XIAO ESP32C3 is connected directly via the **inline connector** on the Grove Vision AI V2.

### 🔌 Wiring Diagram

| XIAO ESP32C3 | Grove Vision AI V2 | Description |
| :--- | :--- | :--- |
| **5V** | **VCC** | Power |
| **GND** | **GND** | Ground |
| **D6 (TX)** | **RX** | UART Transmit |
| **D7 (RX)** | **TX** | UART Receive |
| **D3** | **RST** | Hardware Reset (Optional but recommended) |

---

## 📦 Software Dependencies

### 1. Arduino (Microcontroller)

* **Library**: [Seeed_Arduino_SSCMA](https://github.com/Seeed-Studio/Seeed_Arduino_SSCMA)
* **Board Support**: ESP32 by Espressif Systems (Tested on **v3.3.7**)

### 2. Processing (PC Client)

* **Processing IDE**: [processing.org](https://processing.org/)
* **Library**: `processing.serial.*` (Included by default)

### 3. Python (PC Client)

Install the following via pip:

```bash
pip install pyserial opencv-python numpy
```

---

## 🚀 How to Use

### Step 1: Flash the XIAO

1. Open `VisionAI_Xiao/VisionAI_Xiao.ino` in the Arduino IDE.
2. Select **XIAO ESP32C3** as your board.
3. Upload the sketch.
4. Verify in the Serial Monitor (921600 baud) that you see "Streaming Started."

#### Option B: Arduino CLI

If you prefer the command line, use the following commands. Note that `arduino-cli` may need to be pointed to your custom sketchbook folder if it differs from the default.

```bash
# 1. (Optional) Point CLI to your custom Arduino folder if libraries are already there
# Example: arduino-cli config set directories.user ~/Src/Arduino
arduino-cli config set directories.user <your-sketchbook-path>

# 2. Install required library (if not already present in your sketchbook)
arduino-cli lib install "Seeed Arduino SSCMA"

# 2. Compile the sketch
arduino-cli compile --fqbn esp32:esp32:XIAO_ESP32C3 VisionAI_Xiao/

# 3. Upload to the board (replace /dev/cu.usbmodem... with your port)
arduino-cli upload -p /dev/cu.usbmodem133201 --fqbn esp32:esp32:XIAO_ESP32C3 VisionAI_Xiao/
```

### Step 2: Run the PC Client

#### Option A: Processing

1. Open `VisionAI_Processing/VisionAI_Processing.pde` in Processing.
2. Ensure the `portName` variable matches your device (e.g., `"/dev/cu.usbmodem..."`).
3. Press **Run**.

#### Option B: Python

1. Ensure dependencies are installed.
2. Run the script:

   ```bash
   python3 vision_ai_stream.py
   ```

3. Press **'q'** to exit the stream.

---

## 🧠 Implementation Details

### Protocol

To ensure reliable high-speed data transfer at **921,600 baud**, the system uses a structured binary packet:

1. **Sync Header**: `0xAA 0xBB 0xCC 0xDD` (4 bytes)
2. **Payload Length**: `uint32_t` (4 bytes, little-endian)
3. **JPEG Data**: Raw binary image data

---

## ⚙️ Configuration & Customization

### Changing Resolution

You can change the image quality by modifying the `AT+SENSOR` command in the `setup()` function of the Arduino sketch:

```cpp
atSerial.print("AT+SENSOR=1,1,2\r\n"); // <-- Change the last digit
```

| Value | Resolution | Notes |
| :--- | :--- | :--- |
| **0** | 240 x 240 | Most stable for ESP32C3 memory. |
| **1** | 320 x 240 | QVGA. |
| **2** | 640 x 480 | VGA (High resolution, may requires more RAM). |

> [!IMPORTANT]
> When increasing resolution, the Base64 encoded string grows significantly. If you experience crashes or "SOI=1 EOI=0" errors, you may need to increase `COM_BUFFER_SIZE` or revert to a lower resolution.

### Technical Features

* **JSON Parsing**: The XIAO performs lightweight string searching to extract Base64 image data from the SSCMA JSON events, avoiding heavy JSON parsing libraries.
* **Base64 Decoding**: Hardware-accelerated (mbedtls) decoding on the XIAO to convert data back to binary JPEG before transmission.
* **Retina Support**: Processing sketch includes `pixelDensity(1)` to ensure correct window scaling on high-DPI Mac displays.
