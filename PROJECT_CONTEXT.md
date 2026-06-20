# Dự án Tự động hóa Chữa Bài (Tool S & Tool A)

Tài liệu này lưu trữ toàn bộ bối cảnh, quy trình hoạt động, cấu hình tọa độ và các bài học rút ra trong quá trình xây dựng hệ thống tự động trả bài cho học viên qua Facebook Messenger và Page. Bất kỳ AI Assistant hoặc phiên làm việc IDE nào mới cũng có thể đọc file này để tiếp tục phát triển dự án.

## 1. Tổng quan hệ thống
Hệ thống gồm 2 thành phần chính tương tác qua lại:
- **Tool S (AutoHotkey - `tool_s.ahk`)**: Điều khiển luồng tự động hóa, điều khiển chuột/phím, quản lý cửa sổ (Trình duyệt Chat, Trình duyệt GPT, Tool A), đọc/ghi file `queue.csv`.
- **Tool A (Python - `main.py`)**: Xử lý logic nội dung, đọc các file `.docx` bài làm của học viên từ thư mục Downloads, tổng hợp thành Prompt đưa cho GPT, sau đó nhận kết quả từ GPT để định dạng lại và xuất ra file Word chuẩn.

## 2. Quy trình hoạt động (Workflow)
1. **Khởi tạo (`F8`)**: Tool S đọc `queue.csv` tìm học viên có trạng thái "Chưa làm" hoặc "Lỗi".
2. **Xác định nền tảng**: Dựa vào link (chứa `business.facebook.com` là Page, còn lại là Mess).
3. **Mở khung Chat**: Kích hoạt cửa sổ trình duyệt tương ứng, dán link và mở đoạn chat.
4. **Đợi người dùng (`F9`)**: Người dùng tải file `.docx` của học viên về máy, sau đó nhấn `F9` để tiếp tục.
5. **Gửi lời chào**: Tool S bấm vào khung chat (dùng `ImageSearch` tìm ảnh hoặc dùng tọa độ fallback) và gửi câu *"Anh chữa bài em nha ^^"*.
6. **Tool A tạo Prompt**: Chuyển sang Tool A, load toàn bộ file `.docx` vừa tải, tạo prompt rồi copy vào Clipboard. (Tool S đổi tên file `.docx` thành `.done` để tránh trùng lặp cho học viên sau).
7. **Gửi cho ChatGPT**: Chuyển sang cửa sổ GPT, dán prompt và gửi.
8. **Đợi GPT sinh chữ (Bước 1 - Mũi tên)**: Tool S liên tục quét vùng tọa độ `1629, 343` để tìm ảnh mũi tên cuộn trang `scroll.png`. Thấy mũi tên thì bấm vào để cuộn xuống đáy.
9. **Đợi GPT sinh chữ (Bước 2 - Nút Copy)**: Tool S quét vùng tọa độ `1453, 418` để tìm ảnh nút `copy.png`. Thấy nút Copy tức là GPT đã viết xong, tiến hành bấm copy nội dung.
10. **Tool A định dạng**: Chuyển về Tool A, dán kết quả thô từ GPT, Tool A sẽ định dạng lại và tự động xuất ra file Word mới, đồng thời copy nội dung đã làm đẹp vào Clipboard.
11. **Trả bài**: Chuyển lại cửa sổ Chat, dán nội dung cuối cùng và gửi.
12. **Cập nhật Queue**: Ghi đè trạng thái "Đã làm" vào file `queue.csv`. Kết thúc 1 vòng lặp.

## 3. Cấu hình Nhận diện Hình ảnh & Tọa độ
Hệ thống sử dụng **Tọa độ tuyệt đối (Screen)** cho mọi thao tác quét và click chuột.

### Các hình ảnh (Lưu cùng thư mục `tool_s.ahk`):
- `scroll.png`: Nút mũi tên cuộn xuống của GPT. Phải được cắt cực kỳ sát viền tròn, không dính background hay text.
  - Vùng quét: Ô `400x400` pixel, tâm tại `1629, 343`.
- `copy.png`: Nút copy của GPT. Cắt sát viền 2 ô vuông.
  - Vùng quét: Ô `400x400` pixel, tâm tại `1453, 418`.
- `page_chat.png`: Chữ "Reply in Messenger..." trên nền trắng của ô chat Page. Không lấy dính Avatar.
  - Vùng quét: Ô `600x400` pixel, tâm tại `922, 491`.
  - Fallback nếu không thấy ảnh: `914, 438`.
- `mess_chat.png`: Khu vực nhập liệu của Messenger (chữ "Aa" hoặc khoảng trống mờ).
  - Vùng quét: Toàn màn hình.
  - Fallback nếu không thấy ảnh: `890, 495`.

## 4. Các "bài học xương máu" (Cần lưu ý khi debug)
- **Cắt ảnh ImageSearch**: Chữ của GPT cuộn liên tục đằng sau các nút (mũi tên, copy). Nếu ảnh crop dính chữ ở background, ImageSearch sẽ thất bại. Cần cắt thật sát phần tĩnh của nút.
- **Tọa độ Screen vs Window**: Các tool như Zalo Snipping xuất ra tọa độ Screen (tuyệt đối). Phải thiết lập `CoordMode("Pixel", "Screen")` và `CoordMode("Mouse", "Screen")` trong AHK để đảm bảo độ chuẩn xác.
- **Lỗi nhầm cửa sổ (Mess và GPT)**: Cửa sổ Mess và cửa sổ GPT **PHẢI** là 2 cửa sổ độc lập (kéo tách tab ra). Nếu để chung 1 cửa sổ trình duyệt, Tool S sẽ không thể tự chuyển tab mà chỉ kích hoạt cửa sổ hiện tại, gây lỗi dán nhầm link.
- **Excel khóa file CSV**: Khi người dùng đang mở hoặc click vào ô trong file `queue.csv` bằng Excel, file sẽ bị khóa. Tool S không thể ghi đè trạng thái "Đã làm". Cần tắt file CSV trước khi cho Tool S chạy vòng lặp cập nhật.
- **Xử lý nhiều file**: Tool S đã được nâng cấp để đọc toàn bộ các file `.docx` tải về bằng cách truyền Array qua giao diện chọn file của Tool A, sau đó đổi tên tất cả thành `.done`.
