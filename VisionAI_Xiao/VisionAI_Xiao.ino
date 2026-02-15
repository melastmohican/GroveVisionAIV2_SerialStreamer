#include <Seeed_Arduino_SSCMA.h>
#include <mbedtls/base64.h>

#define COM_BUFFER_SIZE 32768
#define JPG_BUFFER_SIZE 24576

// Globals
SSCMA AI;
HardwareSerial atSerial(0); // D7=RX, D6=TX
const uint8_t HEADER[] = {0xAA, 0xBB, 0xCC, 0xDD};
unsigned char jpeg_buf[JPG_BUFFER_SIZE];

/**
 * v4.1 Corrected Baseline onData callback
 */
void onData(const char *resp, size_t len) {
  // Find the start of the image field (flexibly)
  const char *img_key = "\"image\"";
  const char *pos = strstr(resp, img_key);
  if (!pos)
    return;

  pos += strlen(img_key);
  const char *start = strchr(pos, '\"');
  if (!start)
    return;
  start++; // Move inside the opening quote

  // Find the end of the Base64 string
  const char *end = strchr(start, '\"');
  if (!end)
    return;

  size_t b64_len = end - start;
  if (b64_len == 0 || b64_len > (COM_BUFFER_SIZE - 200))
    return;

  size_t jpeg_size = 0;
  int ret = mbedtls_base64_decode(jpeg_buf, JPG_BUFFER_SIZE, &jpeg_size,
                                  (const unsigned char *)start, b64_len);

  if (ret == 0 && jpeg_size > 0) {
    // Send standard 4-byte header to Processing
    Serial.write(HEADER, 4);
    uint32_t len32 = (uint32_t)jpeg_size;
    Serial.write((uint8_t *)&len32, 4);
    Serial.write(jpeg_buf, jpeg_size);
  }
}

void setup() {
  // Corrected speed: 921600 (Module default)
  Serial.begin(921600);
  while (!Serial && millis() < 3000)
    ;
  Serial.println("\n--- Grove Vision AI V2 Streamer ---");

  // UART Setup
  atSerial.setRxBufferSize(COM_BUFFER_SIZE);
  atSerial.begin(921600, SERIAL_8N1, D7, D6);

  // Hardware Reset
  pinMode(D3, OUTPUT);
  digitalWrite(D3, LOW);
  delay(200);
  digitalWrite(D3, HIGH);
  delay(2500);

  // Library Start
  AI.begin(&atSerial);

  // Resolution and Streaming
  atSerial.print("AT+SENSOR=1,1,2\r\n");
  delay(500);
  atSerial.print("AT+SAMPLE=-1\r\n");
  Serial.println("Corrected stream started at 921600 baud.");
}

void loop() { AI.fetch(onData); }
