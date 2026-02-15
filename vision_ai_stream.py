import serial
import cv2
import numpy as np
import struct
import time

# Configuration
PORT = "/dev/cu.usbmodem133201"
BAUD = 921600
HEADER = b'\xaa\xbb\xcc\xdd'

def main():
    print(f"Connecting to {PORT} at {BAUD} baud...")
    try:
        ser = serial.Serial(PORT, BAUD, timeout=1)
    except Exception as e:
        print(f"Error: Could not open serial port: {e}")
        return

    print("Connected. Searching for stream...")
    
    cv2.namedWindow("Grove Vision AI V2 - Python Streamer", cv2.WINDOW_AUTOSIZE)
    
    frame_count = 0
    start_time = time.time()
    
    try:
        while True:
            # 1. Sync with Header
            # We read byte by byte until we find the start of our header
            char = ser.read(1)
            if char == b'\xaa':
                next_3 = ser.read(3)
                if next_3 == b'\xbb\xcc\xdd':
                    # 2. Read 4-byte Length (Little Endian)
                    len_bytes = ser.read(4)
                    if len(len_bytes) < 4: continue
                    
                    img_len = struct.unpack('<I', len_bytes)[0]
                    
                    if 0 < img_len < 200000:
                        # 3. Read JPEG Data
                        img_data = ser.read(img_len)
                        if len(img_data) < img_len: continue
                        
                        # 4. Decode and Display
                        nparr = np.frombuffer(img_data, np.uint8)
                        frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
                        
                        if frame is not None:
                            frame_count += 1
                            
                            # Simple FPS calculation
                            curr_time = time.time()
                            elapsed = curr_time - start_time
                            if elapsed > 1.0:
                                fps = frame_count / elapsed
                                cv2.setWindowTitle("Grove Vision AI V2 - Python Streamer", 
                                                 f"Vision AI V2 | {frame.shape[1]}x{frame.shape[0]} | FPS: {fps:.1f}")
                                frame_count = 0
                                start_time = curr_time
                            
                            cv2.imshow("Grove Vision AI V2 - Python Streamer", frame)
            
            # Key handling
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
                
    except KeyboardInterrupt:
        print("\nStopping...")
    finally:
        ser.close()
        cv2.destroyAllWindows()
        print("Done.")

if __name__ == "__main__":
    main()