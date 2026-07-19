# 🚀 HƯỚNG DẪN CÀI ĐẶT TOOL S TRÊN MÁY MỚI

> **Áp dụng cho:** Máy tính Windows 10/11, cài từ đầu hoàn toàn.
> **Thời gian ước tính:** 20-30 phút.

---

## 📋 MỤC LỤC

1. [Cài đặt phần mềm cần thiết](#1-cài-đặt-phần-mềm-cần-thiết)
2. [Clone project từ GitHub](#2-clone-project-từ-github)
3. [Tạo thư mục & cấu hình đường dẫn](#3-tạo-thư-mục--cấu-hình-đường-dẫn)
4. [Cài thư viện Python](#4-cài-thư-viện-python)
5. [Cấu hình Chrome Profiles](#5-cấu-hình-chrome-profiles)
6. [Cài Chrome Extension (Ext_S)](#6-cài-chrome-extension-ext_s)
7. [Cấu hình Discord Bot (tùy chọn)](#7-cấu-hình-discord-bot-tùy-chọn)
8. [Chạy Tool S lần đầu](#8-chạy-tool-s-lần-đầu)
9. [Checklist kiểm tra nhanh](#9-checklist-kiểm-tra-nhanh)

---

## 1. CÀI ĐẶT PHẦN MỀM CẦN THIẾT

Tải và cài đặt **TẤT CẢ** các phần mềm sau:

| # | Phần mềm | Link tải | Ghi chú |
|---|----------|----------|---------|
| 1 | **Git** | https://git-scm.com/downloads/win | Để clone project |
| 2 | **Python 3.10+** | https://www.python.org/downloads/ | ✅ Tick **"Add Python to PATH"** khi cài |
| 3 | **AutoHotkey v2** | https://www.autohotkey.com/ | Chọn bản **v2.0** (không phải v1) |
| 4 | **Google Chrome** | https://www.google.com/chrome/ | Trình duyệt chính |
| 5 | **Microsoft Edge** | Đã có sẵn trên Windows | Dùng cho profile Long |
| 6 | **Microsoft Word** | Office 365 / Office 2019+ | Để mở file .docx |

### Kiểm tra đã cài đúng chưa
Mở **PowerShell** hoặc **CMD**, gõ từng lệnh:
```powershell
git --version        # Phải ra git version x.x.x
python --version     # Phải ra Python 3.10 trở lên
```

---

## 2. CLONE PROJECT TỪ GITHUB

Mở **PowerShell** và chạy:

```powershell
# Clone vào ổ D (hoặc đổi thành ổ bạn muốn)
cd D:\
git clone https://github.com/HoangLongDo-cell/AutoToolS.git A_Tool_S_Simple
```

Kết quả: Thư mục `D:\A_Tool_S_Simple` sẽ chứa toàn bộ code.

---

## 3. TẠO THƯ MỤC & CẤU HÌNH ĐƯỜNG DẪN

### 3.1. Tạo thư mục Downloads riêng (BẮT BUỘC)

Tool S cần một thư mục Downloads riêng để giám sát file tải về. Tạo thư mục sau:

```powershell
mkdir "D:\HoangLong_Data\Download"
mkdir "D:\WT_INPUT"
```

> ⚠️ **Nếu muốn dùng đường dẫn khác**, cần sửa ở **3 file** sau:

| File | Dòng cần sửa | Biến |
|------|--------------|------|
| `tool_s.ahk` | Dòng 43 | `global tool_a_downloads := "D:\HoangLong_Data\Download"` |
| `download_watcher.py` | Dòng 12-14 | `DOWNLOAD_DIR`, `TEMP_PATH_FILE`, `WATCHER_STATE_FILE` |
| `Tool_A\config.json` | Toàn file | `input_folder`, `downloads_folder` |

### 3.2. Đặt Chrome tải về đúng thư mục

1. Mở Chrome → Settings → Downloads
2. Đổi Location thành: `D:\HoangLong_Data\Download`
3. BẬT "Ask where to save each file" → **TẮT** (để tự tải về thư mục đã chọn)

---

## 4. CÀI THƯ VIỆN PYTHON

Mở PowerShell, di chuyển vào thư mục project và cài:

```powershell
cd D:\A_Tool_S_Simple

# Cài cho Tool A (OCR, xử lý Word)
pip install -r Tool_A\requirements.txt

# Cài cho Discord Bot (tùy chọn)
pip install discord.py
```

### Thư viện sẽ được cài:
- `python-docx` — Đọc/ghi file Word (.docx)
- `pyperclip` — Copy/paste clipboard
- `pywin32` — Tương tác Windows API
- `discord.py` — Discord Bot (tùy chọn)

---

## 5. CẤU HÌNH CHROME PROFILES

Tool S sử dụng **nhiều Chrome Profile** để tách biệt các tài khoản Facebook Page và ChatGPT. Mỗi profile cần đăng nhập sẵn tài khoản tương ứng.

### 5.1. Tạo Chrome Profile

1. Mở Chrome → Click avatar góc trên phải → **"Add"** → Tạo profile mới
2. Lặp lại cho đến khi đủ số profile cần thiết

### 5.2. Xác định tên Profile Directory

Mỗi profile có một tên thư mục (ví dụ: `Default`, `Profile 1`, `Profile 2`...). Để tìm:

1. Mở Chrome với profile đó
2. Gõ vào thanh địa chỉ: `chrome://version`
3. Tìm dòng **"Profile Path"**, tên thư mục cuối cùng chính là tên profile
   - Ví dụ: `C:\Users\Admin\AppData\Local\Google\Chrome\User Data\Profile 24` → tên là `Profile 24`

### 5.3. Cập nhật tên Profile vào file cấu hình

Mở file `setup_workspace.ahk` và sửa phần đầu:

```autohotkey
; ====================================================================
; CẤU HÌNH TÊN PROFILE VÀ ĐƯỜNG DẪN - BẠN HÃY CHỈNH SỬA Ở ĐÂY
; ====================================================================
EdgeProfileLong    := "Default"      ; Profile Edge cho Long (mở Page FB)
ChromeProfileLong  := "Default"      ; Profile Chrome cho Long (mở GPTs)
ChromeProfileDuong := "Profile 24"   ; Profile Chrome cho Dương
ChromeProfileThao  := "Profile 2"    ; Profile Chrome cho Thảo
ChromeProfileMess  := "Default"      ; Profile Chrome cho Messenger
```

### 5.4. Đăng nhập sẵn trên mỗi Profile

Mở từng Chrome Profile và đăng nhập:

| Profile | Cần đăng nhập | Trang |
|---------|--------------|-------|
| Long (Edge) | FB Page Long | business.facebook.com |
| Long (Chrome) | ChatGPT Long | chatgpt.com |
| Dương (Chrome) | FB Page Dương + ChatGPT Dương | business.facebook.com + chatgpt.com |
| Thảo (Chrome) | FB Page Thảo + ChatGPT Thảo | business.facebook.com + chatgpt.com |
| Mess (Chrome) | FB Messenger | facebook.com/messages |

> 💡 **Mẹo:** Đăng nhập MỘT LẦN rồi tick "Remember me" / "Stay logged in" để không cần đăng nhập lại.

---

## 6. CÀI CHROME EXTENSION (Ext_S)

Extension này chặn popup/redirect khi Tool S tự động thao tác trên trình duyệt.

1. Mở Chrome → gõ `chrome://extensions`
2. BẬT **"Developer mode"** (góc trên bên phải)
3. Click **"Load unpacked"**
4. Chọn thư mục: `D:\A_Tool_S_Simple\Ext_S`
5. Extension sẽ xuất hiện trong danh sách

> ⚠️ **Cài extension cho TẤT CẢ các Chrome Profile** đang sử dụng (Long, Dương, Thảo, Mess).

---

## 7. CẤU HÌNH DISCORD BOT (Tùy chọn)

Discord Bot cho phép điều khiển Tool S từ xa (dừng, xem trạng thái). **Bỏ qua bước này nếu không cần.**

### 7.1. Tạo Bot trên Discord Developer Portal

1. Vào https://discord.com/developers/applications
2. Click **"New Application"** → đặt tên "Tool S Bot"
3. Vào tab **"Bot"**:
   - Click **"Reset Token"** → Copy token
   - BẬT **"MESSAGE CONTENT INTENT"** trong Privileged Gateway Intents
4. Vào tab **"OAuth2"** → URL Generator:
   - Scope: chọn **"bot"**
   - Permissions: chọn **"Send Messages"** + **"Read Message History"**
   - Copy link invite → mở link → thêm bot vào server Discord của bạn

### 7.2. Lưu Token

Tạo file `discord_bot_token.txt` trong thư mục Tool S:

```
D:\A_Tool_S_Simple\discord_bot_token.txt
```

Nội dung file chỉ chứa **MỘT DÒNG** là token bot:
```
MTUyMDA2...YOUR_TOKEN_HERE
```

> 🔒 **QUAN TRỌNG:** KHÔNG BAO GIỜ chia sẻ token này công khai. File này đã được gitignore.

### 7.3. Cấu hình Webhook (tùy chọn thêm)

Nếu muốn nhận thông báo qua Discord Webhook, sửa dòng 15 trong `tool_s.ahk`:
```autohotkey
global discord_webhook := "YOUR_WEBHOOK_URL_HERE"
```

Cách lấy Webhook: Server Settings → Integrations → Webhooks → New Webhook → Copy URL

---

## 8. CHẠY TOOL S LẦN ĐẦU

### Bước 1: Mở Workspace
- Double-click file `tool_s.ahk` → Bảng điều khiển **"Tool S - Bảng Điều Khiển"** sẽ hiện lên
- Bấm **"🖥️ 1. setup_workspace"** → Tool sẽ tự mở tất cả cửa sổ cần thiết

### Bước 2: Cài đặt cửa sổ
- Bấm **"⚙️ 2. Cài đặt cửa sổ"** → Làm theo hướng dẫn trên màn hình
- Lần lượt click vào từng cửa sổ rồi bấm **F9** để lưu Window ID

### Bước 3: Thêm học viên
- Bấm **"➕ 3. Thêm học viên"** → Điền thông tin → Thêm vào queue

### Bước 4: Chạy
- Bấm **"🚀 3b. Auto"** để chạy tự động
- Hoặc **"👁️ 3a. Quan sát"** để chạy từng bước có xác nhận

---

## 9. CHECKLIST KIỂM TRA NHANH

Đánh dấu ✅ khi hoàn thành từng mục:

```
[ ] Git đã cài
[ ] Python 3.10+ đã cài (có trong PATH)
[ ] AutoHotkey v2 đã cài
[ ] Project đã clone về D:\A_Tool_S_Simple
[ ] Thư mục D:\HoangLong_Data\Download đã tạo
[ ] Thư mục D:\WT_INPUT đã tạo
[ ] pip install -r Tool_A\requirements.txt thành công
[ ] Chrome Profiles đã tạo đủ và đăng nhập sẵn
[ ] setup_workspace.ahk đã sửa đúng tên Profile
[ ] Chrome Extension (Ext_S) đã load vào tất cả Profile
[ ] Chrome đặt Download folder = D:\HoangLong_Data\Download
[ ] (Tùy chọn) discord_bot_token.txt đã tạo
[ ] tool_s.ahk chạy được, bảng điều khiển hiện ra
[ ] setup_workspace mở đúng tất cả cửa sổ
[ ] Cài đặt cửa sổ (F9) thành công
```

---

## ❓ CÁC LỖI THƯỜNG GẶP

| Lỗi | Nguyên nhân | Cách sửa |
|-----|-------------|----------|
| `python is not recognized` | Python chưa thêm vào PATH | Cài lại Python, tick "Add to PATH" |
| `ModuleNotFoundError: No module named 'docx'` | Chưa cài thư viện | `pip install -r Tool_A\requirements.txt` |
| Tool S bảng điều khiển không hiện | AutoHotkey v1 thay vì v2 | Cài AutoHotkey v2.0 |
| Chrome mở nhưng không đúng Profile | Tên profile sai | Kiểm tra lại `chrome://version` |
| Extension không hoạt động | Chưa bật Developer Mode | Bật Developer Mode trong `chrome://extensions` |
| Discord Bot không chạy | Token sai hoặc chưa bật Intent | Kiểm tra token + bật MESSAGE CONTENT INTENT |
| Không tìm thấy file tải về | Chrome tải về thư mục sai | Đổi Chrome Downloads → `D:\HoangLong_Data\Download` |

---

## 📁 CẤU TRÚC THƯ MỤC

```
D:\A_Tool_S_Simple\
├── tool_s.ahk                  ← Script chính (AHK v2)
├── setup_workspace.ahk         ← Tự mở workspace
├── shutdown_workspace.ahk      ← Đóng workspace
├── discord_bot.py              ← Bot Discord điều khiển từ xa
├── download_watcher.py         ← Giám sát file tải về
├── thong_tin_s.txt             ← Quy tắc chữa bài (gửi vào GPTs)
├── queue.csv                   ← Danh sách học viên (tự tạo)
├── settings.ini                ← Cấu hình Window IDs (tự tạo)
├── discord_bot_token.txt       ← Token bot Discord (TỰ TẠO, KHÔNG PUSH)
├── notify_channel.txt          ← Channel ID Discord (tự tạo)
├── run_discord_bot.bat         ← Chạy bot riêng lẻ
├── fix_wifi.bat                ← Fix WiFi
├── fix_wifi_admin.ps1          ← Fix WiFi (Admin)
├── Ext_S\                      ← Chrome Extension
│   ├── manifest.json
│   ├── background.js
│   ├── content.js
│   └── interceptor.js
├── Tool_A\                     ← OCR & xử lý Word
│   ├── main.py
│   ├── run.bat
│   ├── config.json
│   └── requirements.txt
├── History\                    ← Lưu lịch sử xử lý
└── *.png                       ← Icons & screenshots cho OCR
```

---

> 📝 **Lưu ý cuối:** Sau khi setup xong, mỗi lần mở máy chỉ cần:
> 1. Double-click `tool_s.ahk`
> 2. Bấm "setup_workspace"
> 3. Bấm "Cài đặt cửa sổ" (chỉ cần lần đầu mỗi phiên)
> 4. Thêm học viên → Chạy Auto!
