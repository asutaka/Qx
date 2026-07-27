# Kế Hoạch Triển Khai & Phát Triển Ứng Dụng Quiz Arena (Web to Flutter Migration Plan)

Tài liệu này trình bày kế hoạch chi tiết để di chuyển (migrate) và mở rộng từ nguyên mẫu (prototype) web hiện tại sang ứng dụng di động chính thức sử dụng **Flutter**.

---

## 🗺️ Lộ Trình Phát Triển (Roadmap)

### Giai Đoạn 1: Khởi Tạo Dự Án & Chuyển Đổi Giao Diện (UI Porting)
- **Thiết lập Project Flutter**: Cấu hình project với mô hình quản lý trạng thái sạch (khuyến nghị sử dụng **BLoC** hoặc **Provider/Riverpod**).
- **Porting CSS Neon Glassmorphism sang Flutter**:
  - Tái tạo phong cách kính mờ sử dụng các widget `BackdropFilter`, `ClipRRect` và custom `BoxDecoration` có màu nền mờ và viền gradient.
  - Cấu hình hệ thống font chữ (Outfit và Space Grotesk từ Google Fonts).
- **Thiết kế Game Screen**:
  - **Sảnh (Lobby)**: Giao diện thẻ lựa chọn chế độ chơi và quà tặng hàng ngày.
  - **Single Mode Screen**: Hộp thoại hiển thị câu hỏi và 4 phương án lựa chọn trực quan.
  - **Battle Mode Screen**: Sử dụng `Stack` và `AnimatedPositioned` để tạo hiệu ứng thanh đua (racing track) hoạt họa 2 nhân vật (Player vs Bot) chạy đua thời gian thực dựa trên số câu trả lời đúng.
  - **Cửa Hàng (Shop)**: Giao diện lưới chọn mũ, giày và hiệu ứng.

---

### Giai Đoạn 2: Xây Dựng Core Logic & Cơ Sở Dữ Liệu Nội Bộ
- **State Management**:
  - Quản lý trạng thái vòng đời trò chơi (chuẩn bị trận đấu, đếm ngược 30 giây, hiển thị đáp án 5 giây, kết thúc game).
  - Quản lý ví vàng và trạng thái sở hữu/trang bị vật phẩm.
  - **Cấu hình cấp độ khó tăng dần trong Single Mode** (Khi kết nối API OTDB):
    - Câu 1 - 10: Tải câu hỏi từ `TriviaDifficulty.easy`
    - Câu 11 - 30: Tải câu hỏi từ `TriviaDifficulty.medium`
    - Câu 31 - 100: Tải câu hỏi từ `TriviaDifficulty.hard`
  - **Cấu hình độ khó trong Battle Mode**:
    - Không truyền tham số độ khó (`difficulty = TriviaDifficulty.any`) để hệ thống tự động tải ngẫu nhiên các câu hỏi từ dễ đến khó cho 10 câu hỏi của trận đấu.
- **Thay thế LocalStorage bằng SQLite (`sqflite`)**:
  - Khởi tạo database local lưu trữ thông tin người dùng (vàng hiện có, các vật phẩm đã mua, cài đặt âm lượng/ngôn ngữ).
  - Lưu trữ thành tích cá nhân cao nhất (High Scores) để hiển thị cục bộ trên Leaderboard.

---

### Giai Đoạn 3: Tích Hợp SDK Di Động Thực Tế (Native SDK Integration)
Tại giai đoạn này, các tính năng giả lập (simulation) của prototype web sẽ được thay thế bằng SDK gốc trên Android/iOS:

1. **Google ML Kit On-Device Translation (`google_mlkit_translation`)**:
   - Khi người dùng thay đổi ngôn ngữ trong Cài Đặt, gọi SDK để tải xuống file mô hình ngôn ngữ gốc (khoảng 30MB) về bộ nhớ máy cục bộ.
   - Hiển thị thanh tiến trình thực tế do SDK báo về.
   - Thực hiện dịch câu hỏi và 4 đáp án hoàn toàn offline mà không cần kết nối mạng.
2. **Google Mobile Ads (`google_mobile_ads`)**:
   - Tích hợp quảng cáo video phần thưởng (Rewarded Video Ads) khi người dùng kích hoạt quyền trợ giúp **Trả lời 2 lần (Double Answer)**.
   - Tích hợp quảng cáo xen kẽ (Interstitial Ads) khi kết thúc lượt chơi Single Mode hoặc Battle Mode để tối ưu doanh thu.

---

### Giai Đoạn 4: Đồng Bộ Hóa Backend (Firebase Integration)
- **Firebase Authentication**: Hỗ trợ đăng nhập ẩn danh (Anonymous) hoặc đăng nhập qua Google/Facebook để lưu trữ dữ liệu đám mây.
- **Firebase Cloud Firestore**:
  - Lưu bảng xếp hạng người dùng trực tuyến (Global Leaderboard) để hiển thị danh sách Top 10 thế giới theo thời gian thực.
  - Hệ thống tự động đẩy thành tích mới của người chơi lên Firestore khi kết thúc game.
- **Dynamic Question Loading**: 
  - Đưa ngân hàng câu hỏi lên Firebase Firestore hoặc lưu trữ dưới dạng file JSON được tải từ CDN về máy khi khởi động trò chơi, giúp dễ dàng cập nhật/thêm câu hỏi mới mà không cần cập nhật ứng dụng.

---

### Giai Đoạn 5: Kiểm Thử & Phát Hành (Testing & Release)
- **Kiểm thử đa thiết bị**: Đo hiệu năng hoạt họa chạy đua trên các dòng máy cấu hình thấp để tối ưu hóa CPU/GPU.
- **Kiểm thử dịch offline**: Đảm bảo dịch thuật hoạt động mượt mà khi thiết bị ngắt kết nối mạng hoàn toàn.
- **Đóng gói & Phát hành**: Build bản phát hành (`.apk`, `.aab`, `.ipa`) và đưa lên Google Play Store & Apple App Store.
