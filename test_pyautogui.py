import pyautogui
import time
import sys

# Yêu cầu cài đặt: pip install pyautogui opencv-python
# Dùng confidence=0.8 để cho phép sai số hình ảnh (giống *80 của AHK)

print("=== BẮT ĐẦU QUÉT BẰNG PYAUTOGUI ===")
print("Bạn có 3 giây để mở Facebook lên màn hình...")
time.sleep(3)

def test_scan(image_name):
    print(f"\nĐang tìm ảnh '{image_name}'...")
    try:
        # locateCenterOnScreen sẽ trả về tọa độ (x, y) của tâm bức ảnh
        location = pyautogui.locateCenterOnScreen(image_name, confidence=0.8)
        if location:
            print(f"✅ THÀNH CÔNG! Tìm thấy '{image_name}' tại tọa độ: X={location.x}, Y={location.y}")
            # Tự động di chuyển chuột đến đó để chứng minh
            pyautogui.moveTo(location.x, location.y, duration=0.5)
            print("Đã di chuột đến vị trí vừa tìm được.")
        else:
            print(f"❌ THẤT BẠI: Không tìm thấy '{image_name}' trên màn hình.")
    except pyautogui.ImageNotFoundException:
        print(f"❌ THẤT BẠI: Không tìm thấy '{image_name}' trên màn hình.")
    except Exception as e:
        print(f"LỖI HỆ THỐNG: {e}\n(Bạn đã cài opencv-python chưa? Chạy: pip install opencv-python)")

test_scan('page_chat.png')
test_scan('mess_chat.png')
test_scan('copy.png')

print("\n=== KẾT THÚC ===")
