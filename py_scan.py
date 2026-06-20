import sys
import time
import pyautogui

# Arguments: py_scan.py <image_path> <x> <y> <w> <h> <out_file>
if len(sys.argv) < 7:
    sys.exit(1)

image_path = sys.argv[1]
x, y, w, h = map(int, sys.argv[2:6])
out_file = sys.argv[6]

region = (x, y, w, h)
timeout = 10
start_time = time.time()

while time.time() - start_time < timeout:
    try:
        # locateCenterOnScreen trả về ngay tâm của ảnh, nên không cần offset thêm
        loc = pyautogui.locateCenterOnScreen(image_path, region=region, confidence=0.8)
        if loc:
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(f"{int(loc.x)},{int(loc.y)}")
            sys.exit(0)
    except pyautogui.ImageNotFoundException:
        pass
    except Exception as e:
        pass
    time.sleep(0.1)

# Nếu hết 10 giây không thấy
with open(out_file, "w", encoding="utf-8") as f:
    f.write("NOT_FOUND")
sys.exit(1)
