import processing.serial.*;
import java.io.ByteArrayInputStream;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;

Serial myPort;
byte[] header = {(byte)0xAA, (byte)0xBB, (byte)0xCC, (byte)0xDD};

PImage img;
int frameCount = 0;
String status = "Connecting...";

void setup() {
  size(240, 240);
  pixelDensity(1);
  surface.setResizable(true);
  surface.setTitle("Grove Vision AI V2 Processing");
  
  try {
    String portName = "/dev/cu.usbmodem133201"; 
    // Matching Xiao v4.1 Speed
    myPort = new Serial(this, portName, 921600);
    println("Connected to " + portName + " at 921600 baud.");
  } catch (Exception e) {
    status = "Error: " + e.getMessage();
    printArray(Serial.list());
  }
}

void draw() {
  background(30);
  
  if (myPort != null) {
    // Read as many packets as available
    while (myPort.available() >= 8) {
      if (findHeader()) {
        int imgLen = readInt();
        if (imgLen > 0 && imgLen < 200000) {
          byte[] imgData = new byte[imgLen];
          int bytesRead = 0;
          
          long timeout = millis() + 500; // Shorter timeout for higher speed
          while (bytesRead < imgLen && millis() < timeout) {
            int toRead = myPort.available();
            if (toRead > 0) {
              toRead = Math.min(toRead, imgLen - bytesRead);
              byte[] temp = new byte[toRead];
              myPort.readBytes(temp);
              System.arraycopy(temp, 0, imgData, bytesRead, toRead);
              bytesRead += toRead;
            }
          }
          
          if (bytesRead == imgLen) {
            processImage(imgData);
          }
        }
      }
    }
  }

  if (img != null) {
    image(img, 0, 0);
  }
  
  fill(0, 150);
  rect(0, height - 25, width, 25);
  fill(0, 255, 0);
  text(status, 10, height - 12);
}

boolean findHeader() {
  while (myPort.available() >= 4) {
    int b = myPort.read();
    if ((byte)b == header[0]) {
      byte[] next3 = new byte[3];
      myPort.readBytes(next3);
      if (next3[0] == header[1] && next3[1] == header[2] && next3[2] == header[3]) {
        return true;
      }
    }
  }
  return false;
}

int readInt() {
  byte[] b = new byte[4];
  myPort.readBytes(b);
  return (b[0] & 0xFF) | ((b[1] & 0xFF) << 8) | ((b[2] & 0xFF) << 16) | ((b[3] & 0xFF) << 24);
}

void processImage(byte[] data) {
  try {
    ByteArrayInputStream bis = new ByteArrayInputStream(data);
    BufferedImage bimg = ImageIO.read(bis);
    if (bimg != null) {
      if (img == null || img.width != bimg.getWidth() || img.height != bimg.getHeight()) {
        img = new PImage(bimg.getWidth(), bimg.getHeight(), ARGB);
      }
      bimg.getRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
      img.updatePixels();
      frameCount++;
      status = "Frames: " + frameCount + " [" + img.width + "x" + img.height + "]";
      if (img.width != width || img.height != height) {
        surface.setSize(img.width, img.height);
      }
    }
  } catch (Exception e) {
    // Silently ignore malformed frames in baseline mode
  }
}
