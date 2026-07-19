# Hướng Dẫn Sử Dụng Tool S Fix (Bản Độc Lập Chuyên Chữa Bài)

Bản này cực xịn, được thiết kế ĐỘC LẬP HOÀN TOÀN để cậu vác đi bất cứ máy nào cũng chạy được, tích hợp sẵn tính năng "Mắt Thần" ngay bên trong mà không cần chạy thêm script Python nào nữa!

## 1. Cài đặt các cửa sổ (Chỉ làm 1 lần khi mới mở máy)
Vì tool phải chuyển qua lại giữa Chat FB, Tool A, và GPT, cậu cần chỉ cho nó biết ai là ai bằng cách:
1. Bấm nút **⚙️ Cài đặt cửa sổ** trên bảng điều khiển.
2. Click chuột vào cửa sổ **Chrome/Edge (Chat FB)** đang chat với học viên → Bấm phím **F9**.
3. Click chuột vào cửa sổ **Tool A** (Python) → Bấm phím **F9**.
4. Click chuột vào cửa sổ **GPT** (Chrome/Edge) → Bấm phím **F9**.

Tool sẽ nhớ 3 cửa sổ này (lưu vào file `config.ini`). Cậu không cần khai báo lại trừ khi tắt trình duyệt bật lại.

## 2. Cách thêm học viên & Dùng Mắt Thần 👁️
1. Bấm **➕ Thêm học viên**.
2. Nhập Link chat, chọn Hệ, chọn Xưng hô.
3. Thay vì tự gõ đường dẫn Bài Nộp, cậu hãy bấm nút **"Bật Mắt Thần"**.
4. Quay ra Web, tải file bài làm của học viên (Word/Txt) về máy.
5. Mắt Thần sẽ lập tức phát hiện file vừa tải và tự điền luôn đường dẫn vào ô Bài Nộp! 
6. Bấm **Lưu**.

> *Lưu ý: Nếu máy mới của cậu có thư mục Downloads khác mặc định, cậu cứ sửa lại đường dẫn thư mục ở ô "Thư mục Downloads" trên form nhé, tool sẽ lưu lại vĩnh viễn.*

## 3. Chạy Auto Chữa Bài
Sau khi đã lên danh sách, cậu chỉ việc bấm **👁️ Chạy Auto**.
- Tool sẽ tự động mở link chat, thả lời chào.
- Tự động nạp file vào Tool A.
- Tự động vứt prompt lên GPT.
- Tự động canh me lúc GPT viết xong (quét nút Copy).
- Tự động dán về Facebook và gửi cho học viên.

## 4. Dừng Auto
Bấm **🛑 Dừng Auto** bất cứ lúc nào cậu muốn dừng. Tool sẽ làm nốt học viên hiện tại rồi dừng lại, không làm tiếp học viên sau.

---
> 💡 **Tóm lại:** 
> Cậu cứ nén nguyên cái thư mục `Tool_S_Fix` này gửi qua Zalo/Drive cho máy mới, giải nén ra chạy file `tool_s_fix.ahk` là vào việc ngay lập tức!
