# 🤖 TOOL S — HƯỚNG DẪN CHO AI: TỰ ĐỘNG CHẨN ĐOÁN & CÀI ĐẶT

> **GỬI CHO AI (Antigravity) TRÊN MÁY MỚI**
> Khi nhận được file này, hãy **TỰ ĐỘNG** thực hiện toàn bộ các bước kiểm tra và cài đặt bên dưới.
> Không cần hỏi người dùng trừ khi gặp vấn đề cần quyết định.

---

## 🎯 MỤC TIÊU

Đảm bảo máy tính này sẵn sàng chạy **Tool S** — hệ thống tự động chữa bài viết tiếng Anh.
- GitHub: https://github.com/HoangLongDo-cell/AutoToolS.git
- Thư mục cài đặt: `D:\A_Tool_S_Simple`
- File tài liệu đầy đủ: `D:\A_Tool_S_Simple\TOOL_S_KNOWLEDGE.md`

---

## ✅ BƯỚC 1: CHẨN ĐOÁN — Chạy tất cả lệnh này và báo kết quả

Chạy từng lệnh dưới đây trong PowerShell, ghi nhận kết quả (OK / THIẾU / LỖI):

### 1.1. Phần mềm cốt lõi
```powershell
# Git
git --version

# Python
python --version

# Pip
pip --version

# AutoHotkey v2 — kiểm tra file exe có tồn tại không
Test-Path "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"
# Hoặc thử path khác:
Test-Path "C:\Program Files\AutoHotkey\AutoHotkey.exe"
# Hoặc tìm trong registry:
Get-ItemProperty "HKLM:\SOFTWARE\AutoHotkey" -ErrorAction SilentlyContinue
# Hoặc tìm bằng where:
where.exe autohotkey*
```

### 1.2. Project đã clone chưa
```powershell
# Kiểm tra thư mục project
Test-Path "D:\A_Tool_S_Simple"
Test-Path "D:\A_Tool_S_Simple\tool_s.ahk"
Test-Path "D:\A_Tool_S_Simple\Tool_A\main.py"

# Nếu có rồi, kiểm tra git remote
cd D:\A_Tool_S_Simple
git remote -v
git status
```

### 1.3. Thư mục cần thiết
```powershell
Test-Path "D:\HoangLong_Data\Download"
Test-Path "D:\WT_INPUT"
Test-Path "D:\A_Jobs_Tool\Nhận xét Mess"
```

### 1.4. Thư viện Python
```powershell
pip show python-docx
pip show pyperclip
pip show pywin32
pip show discord.py
```

### 1.5. Chrome & Edge
```powershell
# Chrome
Test-Path "C:\Program Files\Google\Chrome\Application\chrome.exe"
Test-Path "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"

# Edge
Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Liệt kê Chrome Profiles đang có
Get-ChildItem "${env:LOCALAPPDATA}\Google\Chrome\User Data" -Directory | Where-Object { $_.Name -match "^(Default|Profile \d+)$" } | Select-Object Name
```

### 1.6. File nhạy cảm (cần tạo thủ công)
```powershell
Test-Path "D:\A_Tool_S_Simple\discord_bot_token.txt"
Test-Path "D:\A_Tool_S_Simple\settings.ini"
```

### 1.7. Chrome Extension đã cài chưa
```powershell
# Kiểm tra file extension có sẵn trong project
Test-Path "D:\A_Tool_S_Simple\Ext_S\manifest.json"
```

### 1.8. Ảnh icon cho ImageSearch (RẤT QUAN TRỌNG)
```powershell
# Các ảnh này PHẢI tồn tại và PHẢI khớp với giao diện trên máy hiện tại
Test-Path "D:\A_Tool_S_Simple\page_chat.png"
Test-Path "D:\A_Tool_S_Simple\mess_chat.png"
Test-Path "D:\A_Tool_S_Simple\gpt_chat.png"
Test-Path "D:\A_Tool_S_Simple\gpt_send_ready.png"
Test-Path "D:\A_Tool_S_Simple\icon_file.png"
Test-Path "D:\A_Tool_S_Simple\icon_image.png"
Test-Path "D:\A_Tool_S_Simple\icon_video.png"
Test-Path "D:\A_Tool_S_Simple\icon_loading.png"
Test-Path "D:\A_Tool_S_Simple\send_icon.png"
```

### 1.9. Độ phân giải màn hình
```powershell
# Lấy độ phân giải hiện tại
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
```

---

## 🔧 BƯỚC 2: TỰ ĐỘNG SỬA — Dựa trên kết quả chẩn đoán

### Nếu THIẾU Git:
- Thông báo người dùng tải Git từ https://git-scm.com/downloads/win
- Hoặc thử: `winget install Git.Git`

### Nếu THIẾU Python:
- Thông báo tải từ https://python.org/downloads
- ⚠️ PHẢI tick "Add Python to PATH" khi cài
- Hoặc thử: `winget install Python.Python.3.12`

### Nếu THIẾU AutoHotkey v2:
- Thông báo tải từ https://autohotkey.com
- ⚠️ PHẢI cài bản v2.0 (không phải v1)
- Hoặc thử: `winget install AutoHotkey.AutoHotkey`

### Nếu CHƯA CLONE project:
```powershell
cd D:\
git clone https://github.com/HoangLongDo-cell/AutoToolS.git A_Tool_S_Simple
```

### Nếu ĐÃ CLONE nhưng CŨ:
```powershell
cd D:\A_Tool_S_Simple
git pull origin main
```

### Nếu THIẾU thư mục:
```powershell
New-Item -ItemType Directory -Force -Path "D:\HoangLong_Data\Download"
New-Item -ItemType Directory -Force -Path "D:\WT_INPUT"
```

### Nếu THIẾU thư viện Python:
```powershell
cd D:\A_Tool_S_Simple
pip install -r Tool_A\requirements.txt
pip install discord.py
```

### Nếu THIẾU discord_bot_token.txt:
- Hỏi người dùng: "Cậu có token Discord Bot không? Nếu có thì dán vào đây, tớ sẽ tạo file."
- Tạo file `D:\A_Tool_S_Simple\discord_bot_token.txt` với nội dung token

### Nếu ĐỘ PHÂN GIẢI KHÁC máy gốc (1920x1080):
- ⚠️ CẢNH BÁO: Ảnh icon (page_chat.png, mess_chat.png, gpt_chat.png) có thể không khớp
- Hướng dẫn người dùng chụp lại icon trên máy mới
- Tọa độ cứng trong tool_s.ahk cũng cần điều chỉnh

---

## 📋 BƯỚC 3: BÁO CÁO KẾT QUẢ

Sau khi chẩn đoán xong, hiển thị bảng tổng hợp dạng:

```
╔══════════════════════════════╦═══════════╗
║ Hạng mục                     ║ Trạng thái║
╠══════════════════════════════╬═══════════╣
║ Git                          ║ ✅ OK     ║
║ Python 3.x                   ║ ✅ OK     ║
║ AutoHotkey v2                ║ ❌ THIẾU  ║
║ Project cloned               ║ ✅ OK     ║
║ Thư mục Downloads            ║ ✅ OK     ║
║ Thư mục WT_INPUT             ║ ❌ THIẾU  ║
║ python-docx                  ║ ✅ OK     ║
║ pyperclip                    ║ ✅ OK     ║
║ pywin32                      ║ ❌ THIẾU  ║
║ discord.py                   ║ ⚠️ Tùy chọn║
║ Chrome                       ║ ✅ OK     ║
║ Chrome Profiles              ║ ⚠️ Cần cấu hình║
║ Chrome Extension             ║ ⚠️ Cần load║
║ Icon screenshots             ║ ⚠️ Cần kiểm tra║
║ Discord Bot Token            ║ ❌ THIẾU  ║
║ Độ phân giải                 ║ 1920x1080 ║
╚══════════════════════════════╩═══════════╝
```

Rồi hỏi: **"Tớ tự sửa những cái THIẾU luôn nhé? Hay cậu muốn xem trước?"**

---

## 📐 BƯỚC 4: CẤU HÌNH ĐẶC THÙ MÁY MỚI

Sau khi cài xong phần mềm, cần cấu hình thêm:

### 4.1. Chrome Profiles
Hỏi người dùng:
- "Cậu đã tạo Chrome Profiles cho Long, Dương, Thảo, Mess chưa?"
- Nếu chưa → hướng dẫn tạo
- Nếu rồi → hỏi tên Profile Directory (VD: Default, Profile 1, Profile 24...)
- Cập nhật vào `setup_workspace.ahk` dòng 9-13

### 4.2. Chrome Downloads Folder
Nhắc người dùng:
- Mở Chrome Settings → Downloads → đổi thành `D:\HoangLong_Data\Download`

### 4.3. Chrome Extension
Nhắc người dùng (trên MỖI Chrome Profile):
1. Mở `chrome://extensions`
2. Bật Developer mode
3. Click "Load unpacked" → chọn `D:\A_Tool_S_Simple\Ext_S`

### 4.4. Ảnh Icon (nếu độ phân giải khác)
Nhắc người dùng chụp lại:
- Mở Facebook Page → chụp icon ô chat → lưu đè `page_chat.png`
- Mở Messenger → chụp icon ô chat → lưu đè `mess_chat.png`
- Mở ChatGPT → chụp icon dấu + → lưu đè `gpt_chat.png`
- Chụp nút Send GPT → lưu đè `gpt_send_ready.png`

---

## 🧪 BƯỚC 5: KIỂM TRA CHẠY THỬ

Sau khi setup xong, hướng dẫn người dùng:

1. Double-click `D:\A_Tool_S_Simple\tool_s.ahk`
   - ✅ Phải hiện bảng "Tool S - Bảng Điều Khiển"
   - ❌ Nếu lỗi → kiểm tra AutoHotkey v2

2. Bấm "🖥️ setup_workspace"
   - ✅ Phải mở đúng các cửa sổ Chrome/Edge/Tool A
   - ❌ Nếu lỗi → kiểm tra Chrome Profiles

3. Bấm "⚙️ Cài đặt cửa sổ"
   - Click từng cửa sổ → bấm F9
   - ✅ Phải hiện "Đã cài xong cửa sổ"

4. Thử chạy "👁️ Quan sát" với 1 học viên test

---

## 📚 THÔNG TIN BỔ SUNG

Nếu cần hiểu chi tiết về Tool S (kiến trúc, luồng xử lý, code, design decisions), 
đọc file: `D:\A_Tool_S_Simple\TOOL_S_KNOWLEDGE.md`

File đó chứa:
- Tổng quan hệ thống
- Chi tiết 2488 dòng tool_s.ahk (biến, hàm, phím tắt, luồng xử lý)
- Chi tiết Tool A (460 dòng main.py)
- Chi tiết setup_workspace.ahk, discord_bot.py, download_watcher.py
- Cấu trúc dữ liệu (queue.csv 11 cột, settings.ini)
- Chrome Profiles hiện tại
- Các design decisions đã thực hiện
- Layout màn hình 4 góc

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **setup_workspace.ahk dùng AHK v1**, tool_s.ahk dùng **AHK v2** — cú pháp KHÁC NHAU hoàn toàn
2. **Ảnh icon (.png) phụ thuộc vào độ phân giải** — nếu máy mới khác độ phân giải thì PHẢI chụp lại
3. **Tọa độ Messenger trong tool_s.ahk** (dòng 1138: VX=797, VY=442) có thể cần điều chỉnh
4. **Discord Webhook URL** đã hardcode trong tool_s.ahk dòng 15 — dùng chung, không cần đổi
5. **GPTs URL** hardcode trong setup_workspace.ahk dòng 15 — dùng chung
6. **File nhạy cảm** (token, settings.ini, queue.csv) KHÔNG có trên GitHub — phải tạo thủ công
7. **Giáo án** nằm trong `D:\A_Jobs_Tool\Nhận xét Mess\` — cần copy riêng nếu muốn dùng chức năng gửi giáo án
