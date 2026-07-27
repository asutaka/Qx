# Hướng Dẫn Chạy & Kiểm Tra Prototype Game Quiz Arena (Cập Nhật Cửa Hàng & Dịch Thuật & Ẩn Bars)

Tài liệu này hướng dẫn cách chạy và kiểm tra các tính năng mới đã được cập nhật cho nguyên mẫu (prototype) game Quiz Arena tại thư mục `e:\Data\Quiz`.

---

## 1. Cấu Trúc Các File Đã Cập Nhật
- [index.html](../index.html): 
  - Giao diện **Cửa Hàng (Shop)** với các tab Mũ, Giày, Hiệu ứng.
  - Lựa chọn **Ngôn Ngữ** dịch trong Cài Đặt (English, Tiếng Việt, Tây Ban Nha, Pháp, Nhật).
  - Modal mô phỏng quá trình **tải xuống mô hình Google ML Kit** offline.
- [app.js](../app.js):
  - Logic mua sắm vật phẩm làm đẹp, lưu trữ trạng thái trang bị vào `localStorage`.
  - **Dynamic Runner Rendering**: Render emoji vật phẩm trực tiếp lên nhân vật chạy bộ trong Battle Mode (ví dụ: `🤠🏃‍♂️👟🔥`).
  - Logic mô phỏng tải mô hình ngôn ngữ offline Google ML Kit (chạy từ 0% đến 100% khi lưu cài đặt).
  - **Hiding Top/Bottom Bars**: Tự động ẩn thanh header trên cùng (User Profile/Vàng) và footer tab bên dưới khi vào Single Mode (`quiz`) hoặc Battle Mode (`battle`) để tối ưu hóa không gian hiển thị trên mobile. Hiển thị lại khi quay về Sảnh (Lobby).
- [questions.js](../questions.js):
  - Hỗ trợ ngân hàng câu hỏi đa ngôn ngữ cho dịch thuật offline.

---

## 2. Cách Chạy Thử Nghiệm Trên Máy Tính Của Bạn
Game chạy trực tiếp trên Server local ở địa chỉ:
👉 **[http://127.0.0.1:8080](http://127.0.0.1:8080)**

---

