import os
import time
import tkinter as tk
from tkinter import messagebox
import csv
import io
import sys
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

# Cấu hình đường dẫn (theo đúng máy của bạn)
DOWNLOAD_DIR = r"D:\HoangLong_Data\Download"
TEMP_PATH_FILE = r"D:\A_Tool_S_Simple\temp_paths.txt"
WATCHER_STATE_FILE = r"D:\A_Tool_S_Simple\watcher_active.txt"

def is_watcher_active():
    return os.path.exists(WATCHER_STATE_FILE)

def write_temp_path(filepath):
    """Ghi đường dẫn file tải về ra file tạm để Tool S (AHK) tự động đọc vào form"""
    try:
        with open(TEMP_PATH_FILE, 'w', encoding='utf-8') as f:
            f.write(filepath)
        return True
    except Exception as e:
        print(f"Lỗi khi ghi temp_paths: {e}")
        return False

def get_existing_files():
    if not os.path.exists(DOWNLOAD_DIR):
        return set()
    return set(os.listdir(DOWNLOAD_DIR))

def ask_user(filename):
    """Hiển thị bảng thông báo nhỏ hỏi ý kiến người dùng"""
    root = tk.Tk()
    root.withdraw() # Ẩn cửa sổ chính
    root.attributes("-topmost", True) # Luôn nổi trên cùng
    
    # Hiện popup Yes/No
    result = messagebox.askyesno(
        title="Tool S - Bắt File Tải Về", 
        message=f"Thêm file sau vào danh sách bài cần chữa?\n\n{filename}", 
        parent=root
    )
    root.destroy()
    return result

def main():
    if not os.path.exists(DOWNLOAD_DIR):
        print(f"Chưa tìm thấy thư mục {DOWNLOAD_DIR}, tool sẽ đợi...")
        while not os.path.exists(DOWNLOAD_DIR):
            time.sleep(2)
            
    print(f"Đang giám sát thư mục: {DOWNLOAD_DIR}")
    known_files = get_existing_files()
    
    while True:
        time.sleep(1) # Quét mỗi giây 1 lần
        
        current_files = set(os.listdir(DOWNLOAD_DIR))
        new_files = current_files - known_files
        
        for file in new_files:
            # Bỏ qua các file đang tải dở của trình duyệt và file nháp của Word (~$)
            if file.endswith('.crdownload') or file.endswith('.tmp') or file.startswith('~$'):
                continue
                
            # Chỉ bắt các file Word, PDF hoặc Txt
            if file.lower().endswith(('.docx', '.doc', '.pdf', '.txt')):
                # CHỈ BẮT FILE NẾU ĐÃ BẤM NÚT "LƯU" (BẬT WATCHER)
                if not is_watcher_active():
                    continue
                    
                filepath = os.path.join(DOWNLOAD_DIR, file)
                
                # Đợi 0.5s để hệ điều hành nhả file ra hoàn toàn
                time.sleep(0.5)
                
                # Hỏi người dùng
                if ask_user(file):
                    if write_temp_path(filepath):
                        print(f"Đã cập nhật: {file}")
                    else:
                        print(f"Lỗi khi ghi temp_path.")

        # Cập nhật danh sách file đã biết
        known_files = current_files

if __name__ == "__main__":
    main()
