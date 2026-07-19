# 🧠 TOOL S — TÀI LIỆU TỔNG HỢP TOÀN BỘ (Knowledge File)

> **Mục đích:** File này chứa MỌI thông tin về Tool S để khi mở Antigravity trên máy khác,
> chỉ cần tải file này lên là AI nắm hết ngữ cảnh để làm việc tiếp.
>
> **Cập nhật lần cuối:** 19/07/2026 17:50
> **GitHub:** https://github.com/HoangLongDo-cell/AutoToolS.git
> **Thư mục gốc:** `D:\A_Tool_S_Simple`

---

## 📌 1. TỔNG QUAN

**Tool S** là hệ thống tự động hóa chữa bài viết tiếng Anh cho học viên. Quy trình:
1. Nhận bài làm từ học viên qua Facebook Messenger / Facebook Page
2. Trích xuất nội dung bài làm (Word/Text) → tạo prompt
3. Gửi prompt sang ChatGPT (Custom GPTs) để chữa bài tự động
4. Nhận kết quả → format → gửi lại cho học viên kèm file Word
5. Gửi giáo án (ảnh, video, text, file Word) nếu có

**Các hệ thi được hỗ trợ:**
- APTIS GENERAL (phổ biến nhất)
- VSTEP
- APTIS ADVANCED

---

## 📁 2. CẤU TRÚC THƯ MỤC & FILE

```
D:\A_Tool_S_Simple\
├── tool_s.ahk                  ← Script điều khiển chính (AHK v2.0, 2488 dòng)
├── setup_workspace.ahk         ← Tự mở tất cả cửa sổ cần thiết (AHK v1)
├── shutdown_workspace.ahk      ← Đóng workspace
├── discord_bot.py              ← Bot Discord điều khiển từ xa (169 dòng)
├── download_watcher.py         ← Giám sát thư mục Downloads (92 dòng)
├── thong_tin_s.txt             ← 12 quy tắc chữa bài gửi vào GPTs
├── queue.csv                   ← Danh sách học viên (runtime, gitignored)
├── queue_long.csv              ← Queue riêng cho Long (runtime)
├── queue_duong.csv             ← Queue riêng cho Dương (runtime)
├── queue_thao.csv              ← Queue riêng cho Thảo (runtime)
├── settings.ini                ← Window IDs + worker_mode (runtime, gitignored)
├── discord_bot_token.txt       ← Token bot Discord (BÍ MẬT, gitignored)
├── notify_channel.txt          ← Channel ID Discord (runtime, gitignored)
├── discord_msg_queue.txt       ← Queue tin nhắn Discord (runtime, gitignored)
├── run_discord_bot.bat         ← Chạy bot Discord riêng lẻ
├── fix_wifi.bat                ← Fix WiFi tự động
├── fix_wifi_admin.ps1          ← Fix WiFi (admin)
├── .gitignore                  ← Bảo vệ file nhạy cảm
├── SETUP_MAY_MOI.md            ← Hướng dẫn cài đặt trên máy mới
│
├── Ext_S\                      ← Chrome Extension chặn popup/redirect
│   ├── manifest.json           ← Manifest v3
│   ├── background.js           ← Service worker
│   ├── content.js              ← Content script
│   └── interceptor.js          ← Chặn redirect/popup
│
├── Tool_A\                     ← GUI xử lý bài chữa (Python tkinter)
│   ├── main.py                 ← App chính (460 dòng)
│   ├── run.bat                 ← `python main.py` + pause
│   ├── config.json             ← Cấu hình đường dẫn
│   └── requirements.txt        ← python-docx, pyperclip, pywin32
│
├── History\                    ← Lưu lịch sử xử lý (CSV theo ngày)
│
└── [Assets - Ảnh dùng cho ImageSearch]
    ├── page_chat.png           ← Icon ô chat Facebook Page (để quét tìm)
    ├── mess_chat.png           ← Icon ô chat Messenger (để quét tìm)
    ├── gpt_chat.png            ← Icon ô chat ChatGPT (dấu + bên trái)
    ├── gpt_send_ready.png      ← Nút Send của GPT (check load xong)
    ├── send_icon.png           ← Icon nút gửi
    ├── icon_file.png           ← Icon file đính kèm (Page)
    ├── icon_image.png          ← Icon ảnh đính kèm (Page)
    ├── icon_video.png          ← Icon video đính kèm (Page)
    └── icon_loading.png        ← Icon đang tải
```

---

## ⚙️ 3. CHI TIẾT TỪNG THÀNH PHẦN

### 3.1. tool_s.ahk — Script điều khiển chính

**Ngôn ngữ:** AutoHotkey v2.0 (`#Requires AutoHotkey v2.0`)  
**Kích thước:** ~2488 dòng, ~85KB

#### Biến toàn cục quan trọng:
```
id_mess          — Window ID cửa sổ Messenger
id_page_long     — Window ID cửa sổ Page Long
id_page_duong    — Window ID cửa sổ Page Dương
id_page_thao     — Window ID cửa sổ Page Thảo
id_gpt_long      — Window ID cửa sổ GPTs Long
id_gpt_duong     — Window ID cửa sổ GPTs Dương
id_gpt_thao      — Window ID cửa sổ GPTs Thảo
id_toola         — Window ID cửa sổ Tool A
worker_mode      — 2 hoặc 3 (số người làm)
queue_file       — "queue.csv"
tool_a_downloads — "D:\HoangLong_Data\Download"
discord_webhook  — URL Discord Webhook gửi log
```

#### Phím tắt:
| Phím | Chức năng |
|------|-----------|
| `Ctrl+Y` | Bắt đầu chạy Auto |
| `F7` | Tạm dừng (pause) — hiện dialog chọn thêm HV hoặc tiếp tục |
| `F8` | Dừng khẩn cấp (reload script) |
| `F9` | (Manual) Xác nhận bước tiếp theo |
| `F10` | Copy text đang bôi đen → lưu thành file .txt vào Downloads |

#### Luồng xử lý chính (ProcessQueue):
```
1. Đọc queue.csv → tìm hàng "Chưa làm" (lấy batch 2 hoặc 3 hàng)
2. Phase 1 (song song cho batch):
   a. Mở link chat Facebook → đợi trang tải (ImageSearch icon)
   b. Click vào ô chat → gửi lời chào
   c. (Manual) Đợi F9 tải file / (Auto) dùng đường dẫn bài nộp có sẵn
   d. Chuyển file sang Tool A → chọn hệ thi (F1/F2/F3) → tạo prompt (Ctrl+P)
   e. Mở GPTs → click ô chat → dán prompt → đợi nút Send → Enter
3. Phase 2 (song song cho batch):
   a. Đợi GPTs trả lời (quét icon copy.png, tối đa 200 lần × 4-5s)
   b. Click copy → lấy bài chữa vào clipboard
   c. Mở lại link chat → đợi trang tải
   d. Chuyển sang Tool A → Ctrl+Delete → Ctrl+D → Ctrl+F → Ctrl+Shift+C → Ctrl+W
   e. Quay lại chat → dán bài chữa text → gửi
   f. Gửi file Word (Bài chữa.docx) bằng SetClipboardFiles + Ctrl+V
   g. Gửi giáo án (nếu có)
   h. Cập nhật CSV: "Đã làm" + thời gian
```

#### Hệ thống Smart Wait (ImageSearch):
- **Không dùng Sleep cứng** — quét icon bằng ImageSearch liên tục
- Dùng nhiều mức tolerance: `*80`, `*120`, `*150`
- Sau khi tìm thấy icon → thêm Sleep(2000) buffer
- Fallback: nếu không tìm thấy → dùng tọa độ cố định

#### Click ô chat — Cơ chế IBeam:
1. ImageSearch tìm icon (page_chat.png / mess_chat.png / gpt_chat.png)
2. Từ vị trí icon, di chuột dần (lên/trái/phải) tìm cursor IBeam
3. Khi gặp IBeam → Click 2 lần xác nhận
4. Fallback → click vào tọa độ dự phòng cố định

#### Hàm quan trọng:
| Hàm | Mô tả |
|-----|-------|
| `MainGUI()` | Tạo bảng điều khiển chính |
| `ProcessQueue(mode)` | Vòng lặp xử lý hàng đợi (manual/auto) |
| `ProcessRow_Phase1()` | Mở chat → tạo prompt → gửi GPT |
| `ProcessRow_Phase2()` | Đợi GPT → format → gửi lại chat |
| `AddToQueue_Form()` | Form thêm học viên mới |
| `ShowConfirmDialog()` | Dialog xác nhận trước khi lưu |
| `ClickPageChat()` | Smart click ô chat Facebook Page |
| `ClickMessChat()` | Smart click ô chat Messenger |
| `ClickGptChat()` | Smart click ô chat ChatGPT |
| `SendGiaoAn()` | Gửi toàn bộ nội dung giáo án (text/ảnh/video/file/folder) |
| `WaitForIcon()` | Đợi icon xuất hiện (file/image/video) trước khi Enter |
| `SetClipboardFiles()` | Đặt file vào clipboard (DllCall Windows API) |
| `UpdateCSV()` | Cập nhật trạng thái trong queue.csv |
| `ArchiveHistory()` | Dọn dẹp queue đã hoàn thành → History/ |
| `MarkShiftStart/End()` | Đánh dấu ca làm việc |
| `GetWorkerBySTT()` | Phân công nhân sự theo STT (round-robin) |
| `CheckPause()` | Kiểm tra F7 pause giữa các bước |
| `CheckGradedCounter()` | Mỗi 5 bài → gửi lại Thông tin S cho GPTs relax |
| `PasteThongTinSAll()` | F5 reload + dán Thông tin S vào tất cả GPTs |
| `OpenExcelWithFormat()` | Mở CSV bằng COM Excel + format màu |

#### Phân công nhân sự (Round-robin):
- **Chế độ 2 người:** STT lẻ → Dương, STT chẵn → Long
- **Chế độ 3 người:** STT mod 3: 1→Dương, 2→Long, 0→Thảo

#### Cơ chế điều khiển từ xa:
- **stop_auto.txt** — Tạo file này → Tool S dừng Auto ở bước tiếp
- **pause_auto.txt** — Tạo file này (F7) → Tool S tạm dừng, hiện dialog
- **workspace_active.txt** — Flag workspace đang chạy (cho Discord Bot theo dõi)

#### Discord Webhook Log:
- Gửi log mọi bước quan trọng qua Discord Webhook
- Format: emoji + [Phase/Action] + nội dung
- Bao gồm: bắt đầu, lỗi, hoàn thành, pause, resume, remote stop

---

### 3.2. Tool_A/main.py — GUI xử lý bài chữa

**Ngôn ngữ:** Python 3 + tkinter  
**Kích thước:** 460 dòng  
**Tên cửa sổ:** "WT Prompt Tool"

#### Chức năng:
1. **Chọn file học viên** (Ctrl+U) — hỗ trợ .txt, .docx, .doc
2. **Tạo prompt** (F1/F2/F3) — thêm keyword [aptis gen] / [vstep] / [aptis adv] + nội dung bài
3. **Copy prompt** (Ctrl+P) — sao chép vào clipboard
4. **Dán bài chữa** (Ctrl+D) — nhận kết quả từ GPTs
5. **Định dạng lại** (Ctrl+F) — xóa markdown (**, *, ```, code block), gộp dòng trống, fix số thứ tự
6. **Copy formatted** (Ctrl+Shift+C) — format + copy
7. **Xuất Word** (Ctrl+W) — lưu thành "Bài chữa.docx" (Times New Roman)
8. **Xóa nội dung** (Ctrl+Delete) — clear ô bài chữa

#### Đọc file:
- `.txt` — thử nhiều encoding: utf-8-sig, utf-8, cp1258, cp1252
- `.docx` — dùng python-docx (paragraphs + tables)
- `.doc/.rtf` — dùng win32com.client (Word COM)

#### Config (Tool_A/config.json):
```json
{
    "input_folder": "D:/WT_INPUT",
    "gpt_url": "",
    "downloads_folder": "D:/HoangLong_Data/Download"
}
```

---

### 3.3. setup_workspace.ahk — Tự động mở workspace

**Ngôn ngữ:** AutoHotkey v1 (KHÁC với tool_s.ahk là v2!)

#### Cấu hình Profile (đầu file):
```autohotkey
EdgeProfileLong    := "Default"
ChromeProfileLong  := "Default"
ChromeProfileDuong := "Profile 24"
ChromeProfileThao  := "Profile 2"
ChromeProfileMess  := "Default"
ToolAPath          := A_ScriptDir . "\Tool_A\run.bat"
GptsUrl            := "https://chatgpt.com/g/g-6a596a1268cc81919a9e75265771bea9-chua-wt"
```

#### Trình tự mở:
1. **Góc trên trái (TL):** Page Thảo (nếu 3 người) → Page Dương → Page Long (Edge) → Messenger
2. **Góc dưới trái (BL):** Tool A (run.bat)
3. **Góc trên phải (TR):** GPTs Thảo → GPTs Dương → GPTs Long
4. **Góc dưới phải (BR):** Thư mục Downloads
5. **Ngầm:** download_watcher.py + discord_bot.py

#### Snap Window: Dùng phím tắt Windows 11 (Win+Left/Right + Win+Up/Down + Esc)

---

### 3.4. discord_bot.py — Bot điều khiển từ xa

**Ngôn ngữ:** Python 3 + discord.py

#### Lệnh hỗ trợ:
| Lệnh | Chức năng |
|-------|----------|
| `!stop` | Tạo stop_auto.txt → Tool S dừng Auto |
| `!status` | Hiển thị trạng thái (workspace active, stop pending) |
| `!help` | Danh sách lệnh |

#### Tính năng tự động:
- Kiểm tra workspace_active.txt mỗi 3 giây
- Khi trạng thái thay đổi → gửi thông báo "BẮT ĐẦU" hoặc "DỪNG"
- Lưu channel cuối cùng người dùng chat vào notify_channel.txt

#### Token: Đọc từ `discord_bot_token.txt` hoặc biến môi trường `DISCORD_BOT_TOKEN`

---

### 3.5. download_watcher.py — Giám sát file tải về

**Ngôn ngữ:** Python 3 + tkinter (messagebox)

#### Hoạt động:
1. Quét thư mục `D:\HoangLong_Data\Download` mỗi giây
2. Phát hiện file mới (.docx, .doc, .pdf, .txt)
3. Bỏ qua file đang tải (.crdownload, .tmp, ~$)
4. CHỈ BẮT khi `watcher_active.txt` tồn tại (bấm "Lưu" trong form thêm HV)
5. Hiện popup Yes/No hỏi người dùng
6. Nếu Yes → ghi đường dẫn vào `temp_paths.txt` → Tool S tự đọc vào form

---

### 3.6. Ext_S/ — Chrome Extension

**Manifest V3**  
**Chức năng:** Chặn popup, redirect, và các hành vi gây rối khi Tool S tự động thao tác trên trình duyệt.

---

### 3.7. thong_tin_s.txt — 12 Quy tắc chữa bài

Nội dung gửi vào GPTs mỗi phiên (và mỗi 5 bài). Các quy tắc:
0. Tuân thủ số từ tối đa từng part
1. KHÔNG kèm keyword phân luồng (aptis gen/adv/vstep)
2. KHÔNG dùng code block / khung xám
3. Bắt lỗi dấu chấm sau ký tên + đếm từ chính xác
4. Bài thiếu từ → gợi ý cụ thể
5. Không ép hòa hợp thì máy móc (tense over-correction)
6. Zero-error tolerance — săn lùng mọi lỗi
7. Chữa lỗi bằng tiếng Anh, giải thích bằng tiếng Việt riêng
8. VSTEP Task 1 không cần ký tên, Aptis Gen phải ký tên
9. Lỗi số ít/số nhiều
10. "felt on cloud nine" được phép
11. Tên CLB không cần viết hoa
12. Double check grammar + chính tả

---

## 📊 4. CẤU TRÚC DỮ LIỆU

### queue.csv (11 cột):
```
STT, Link chat, Loại việc, Hệ bài chữa, Gửi giáo án, Mã giáo án, Đường dẫn bài nộp, Trạng thái, Thời gian bắt đầu, Thời gian hoàn thành, Xưng hô
```

| Cột | Ý nghĩa | Ví dụ |
|-----|---------|-------|
| STT | Số thứ tự (integer) hoặc "CA LÀM VIỆC" | 1, 2, 3, "CA LÀM VIỆC" |
| Link chat | URL Facebook chat | https://business.facebook.com/... hoặc https://facebook.com/messages/t/... |
| Loại việc | "Chữa bài" hoặc "Chỉ gửi giáo án" | Chữa bài |
| Hệ bài chữa | "APTIS GENERAL", "VSTEP", "APTIS ADVANCED", hoặc "" | APTIS GENERAL |
| Gửi giáo án | "Có" hoặc "Không" | Có |
| Mã giáo án | Mã thư mục (dùng _ thay \) | gen_bài 2 → D:\A_Jobs_Tool\Nhận xét Mess\gen\bài 2 |
| Đường dẫn bài nộp | Path file, phân cách bằng \| | D:\...\file1.docx\|D:\...\file2.docx |
| Trạng thái | "Chưa làm", "Đang làm", "Đã làm", "Lỗi" | Chưa làm |
| Thời gian bắt đầu | HH:mm | 14:30 |
| Thời gian hoàn thành | HH:mm | 14:45 |
| Xưng hô | Cách xưng hô với học viên | "Anh - Em (Mặc định)", "Mình - Bạn", "Em - Chị", "Em - Anh" |

### settings.ini:
```ini
[WindowIDs]
id_mess=0
id_page_long=0
id_page_duong=0
id_page_thao=0
id_gpt_long=0
id_gpt_duong=0
id_gpt_thao=0
id_toola=0

[Settings]
worker_mode=2

[GradedCounts]
long=0
duong=0
thao=0
```

---

## 🔧 5. DEPENDENCIES & YÊU CẦU HỆ THỐNG

### Phần mềm:
| Phần mềm | Phiên bản | Bắt buộc |
|-----------|----------|----------|
| Windows 10/11 | Bất kỳ | ✅ |
| AutoHotkey v2 | 2.0+ | ✅ (tool_s.ahk) |
| AutoHotkey v1 | 1.1+ | ✅ (setup_workspace.ahk) |
| Python | 3.10+ | ✅ |
| Google Chrome | Bất kỳ | ✅ |
| Microsoft Edge | Bất kỳ | ✅ (Profile Long) |
| Microsoft Word | Office 2019+ | ✅ (đọc .doc/.rtf) |
| Git | Bất kỳ | Tùy chọn |

### Thư viện Python:
```
python-docx>=0.8.11    # Đọc/ghi .docx
pyperclip>=1.8.2       # Clipboard
pywin32>=306            # Windows COM (Word, Excel)
discord.py             # Discord Bot (tùy chọn)
tkinter                # GUI (có sẵn với Python)
```

### Thư mục cần tạo:
```
D:\HoangLong_Data\Download  — Thư mục Downloads chuyên dụng
D:\WT_INPUT                  — Thư mục input cho Tool A
D:\A_Jobs_Tool\Nhận xét Mess — Thư mục chứa giáo án (cấu trúc cây)
```

---

## 🔑 6. THÔNG TIN NHẠY CẢM (KHÔNG PUSH LÊN GITHUB)

Các file sau PHẢI tạo thủ công trên mỗi máy, KHÔNG có trên GitHub:
1. **discord_bot_token.txt** — Token Discord Bot
2. **notify_channel.txt** — Channel ID (tự tạo runtime)
3. **settings.ini** — Window IDs (tự tạo khi cài đặt cửa sổ)
4. **queue.csv** — Danh sách học viên (tự tạo runtime)
5. **discord_msg_queue.txt** — Queue tin nhắn

### Discord Webhook URL (hardcode trong tool_s.ahk dòng 15):
```
https://discordapp.com/api/webhooks/1517897683107319818/4G91ozYWFht7924nWa7l-nWSTxP7N3uyWUtG1OZOxAiP1AP8_2YyY6t5GXj0q2yChfAW
```

### GPTs URL (hardcode trong setup_workspace.ahk dòng 15):
```
https://chatgpt.com/g/g-6a596a1268cc81919a9e75265771bea9-chua-wt
```

---

## 🎯 7. CÁC VẤN ĐỀ ĐÃ GIẢI QUYẾT & DESIGN DECISIONS

### Smart Wait thay vì Sleep cứng:
- **Vấn đề:** Facebook Page load chậm/nhanh không đoán trước được
- **Giải pháp:** ImageSearch quét icon liên tục, không giới hạn thời gian
- **Fallback:** Tọa độ cố định nếu không tìm thấy icon

### IBeam Cursor Detection:
- **Vấn đề:** Không thể click chính xác vào ô chat (vị trí thay đổi)
- **Giải pháp:** Tìm icon → di chuột dần → phát hiện cursor IBeam → click 2 lần

### Batch Processing:
- **Vấn đề:** GPTs mất thời gian trả lời (1-3 phút)
- **Giải pháp:** Gửi prompt cho 2-3 GPTs cùng lúc (Phase 1), rồi đợi tất cả (Phase 2)

### File Lock Protection:
- **Vấn đề:** Excel khóa queue.csv
- **Giải pháp:** Mọi thao tác ghi file đều có try-catch + thông báo tắt Excel

### Mỗi 5 bài gửi lại Thông tin S:
- **Vấn đề:** GPTs quên quy tắc sau nhiều bài
- **Giải pháp:** Bộ đếm CheckGradedCounter, mỗi 5 bài reload + dán lại Thông tin S

### Xưng hô tùy chỉnh:
- **Vấn đề:** Học viên có độ tuổi khác nhau
- **Giải pháp:** Cột "Xưng hô" trong queue.csv, chèn vào đầu prompt cho GPTs

### Migration tự động:
- **Vấn đề:** Cấu trúc CSV thay đổi qua các phiên bản
- **Giải pháp:** Tự động detect và migrate khi khởi động (Migration 1: Loại việc, Migration 2: Xưng hô)

---

## 🔄 8. LUỒNG DỮ LIỆU (DATA FLOW)

```
[Người dùng]
    │
    ├─ Thêm HV ──→ queue.csv (STT, link, hệ, path bài...)
    │
    ├─ Chạy Auto ──→ ProcessQueue()
    │                   │
    │                   ├─ Phase 1 (tất cả HV trong batch)
    │                   │   ├─ Mở FB chat → đợi icon → click ô chat
    │                   │   ├─ Gửi lời chào (theo xưng hô)
    │                   │   ├─ Nạp file vào Tool A (Ctrl+U)
    │                   │   ├─ Chọn hệ thi (F1/F2/F3) → Tạo prompt (Ctrl+P)
    │                   │   └─ Mở GPTs → dán prompt → Enter
    │                   │
    │                   └─ Phase 2 (tất cả HV trong batch)
    │                       ├─ Đợi GPTs trả lời (quét copy.png)
    │                       ├─ Click copy → clipboard
    │                       ├─ Mở lại link chat
    │                       ├─ Tool A: Dán (Ctrl+D) → Format (Ctrl+F) → Copy (Ctrl+Shift+C) → Word (Ctrl+W)
    │                       ├─ Chat: Dán text + Enter
    │                       ├─ Chat: Gửi file Word (SetClipboardFiles)
    │                       ├─ Chat: Gửi giáo án (nếu có)
    │                       └─ Cập nhật CSV: "Đã làm"
    │
    ├─ Discord Bot
    │   ├─ !stop → stop_auto.txt → Tool S dừng
    │   ├─ !status → kiểm tra workspace_active.txt
    │   └─ Auto-notify khi workspace bật/tắt
    │
    └─ Download Watcher
        ├─ Quét thư mục Downloads mỗi giây
        ├─ File mới → popup hỏi Yes/No
        └─ Yes → temp_paths.txt → Tool S đọc vào form
```

---

## 📐 9. LAYOUT MÀN HÌNH

```
┌─────────────────────────┬─────────────────────────┐
│ Góc TRÊN TRÁI (TL)     │ Góc TRÊN PHẢI (TR)      │
│                         │                         │
│ [Messenger]             │ [GPTs Long]             │
│ [Page Long - Edge]      │ [GPTs Dương]            │
│ [Page Dương - Chrome]   │ [GPTs Thảo*]            │
│ [Page Thảo* - Chrome]   │                         │
│                         │                         │
├─────────────────────────┼─────────────────────────┤
│ Góc DƯỚI TRÁI (BL)     │ Góc DƯỚI PHẢI (BR)      │
│                         │                         │
│ [Tool A - WT Prompt]    │ [Thư mục Downloads]     │
│                         │                         │
└─────────────────────────┴─────────────────────────┘
  * Chỉ hiện khi worker_mode = 3
```

---

## 🔌 10. CHROME PROFILES HIỆN TẠI

| Profile | Trình duyệt | Tên thư mục | Đăng nhập |
|---------|-------------|-------------|-----------|
| Long (Page) | Edge | Default | business.facebook.com |
| Long (GPTs) | Chrome | Default | chatgpt.com |
| Dương | Chrome | Profile 24 | business.facebook.com + chatgpt.com |
| Thảo | Chrome | Profile 2 | business.facebook.com + chatgpt.com |
| Messenger | Chrome | Default | facebook.com/messages |

---

## 📝 11. GHI CHÚ KỸ THUẬT

- **setup_workspace.ahk dùng AHK v1**, tool_s.ahk dùng AHK v2 — cú pháp KHÁC NHAU
- **ImageSearch cần ảnh screenshot chính xác** trên máy đang dùng. Nếu đổi máy/độ phân giải → cần chụp lại icon
- **Tọa độ Messenger cố định** (VX=797, VY=442, VW=144, VH=67) — phụ thuộc vào kích thước cửa sổ Snap
- **Tọa độ Page dùng SysGet(76-79)** — tự động lấy vùng virtual screen
- **SetClipboardFiles** dùng Windows API DllCall trực tiếp (DROPFILES struct)
- **WakeLock** bật khi chạy Auto (ES_DISPLAY_REQUIRED | ES_CONTINUOUS) để màn hình không tắt
- **Discord Bot** tự cài discord.py nếu chưa có (os.system pip install)
- **CSV parsing** dùng AHK built-in `Loop Parse, line, "CSV"`
- **Giáo án** được tổ chức theo thư mục, mỗi thư mục có file `thu_tu_gui.txt` chỉ định thứ tự gửi
- **File Word sau khi gửi** được đổi tên thêm `.sent` để tránh gửi lại

---

## 🔮 12. HƯỚNG PHÁT TRIỂN / TODO

- [ ] Hỗ trợ đa độ phân giải (hiện chỉ test trên 1 độ phân giải)
- [ ] Tích hợp thêm kênh giao tiếp (Zalo, Telegram)
- [ ] Dashboard web xem trạng thái realtime
- [ ] Tự động chụp lại icon khi phát hiện đổi giao diện
- [ ] Cơ chế retry khi gặp lỗi thay vì đánh dấu "Lỗi"
