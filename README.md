# Sổ Thu Chi Kakeibo (Money Note Clone - Flutter)

Ứng dụng quản lý chi tiêu cá nhân lấy cảm hứng từ **Money Note (Sổ thu chi)** của Komorebi Inc. theo phương pháp **Kakeibo** Nhật Bản: tối giản, nhập liệu siêu tốc bằng bàn phím máy tính tích hợp, lưu trữ 100% offline trên thiết bị bằng SQLite.

## Cấu trúc dự án

- `lib/main.dart`: Khởi tạo ứng dụng, cấu hình giao diện Sáng/Tối (phong cách giấy Washi Nhật Bản) và thanh điều hướng 4 tab.
- `lib/models/models.dart`: Định nghĩa dữ liệu Danh mục (`CategoryModel`) và Giao dịch (`TransactionModel`).
- `lib/services/database_helper.dart`: Quản lý cơ sở dữ liệu SQLite (`sqflite`) và khởi tạo danh mục mặc định.
- `lib/screens/input_screen.dart`: **Tab 1 (Nhập vào)** - Chuyển đổi Chi/Thu, chọn ngày nhanh, lưới danh mục và bàn phím số tích hợp (`00`, `000`, `AC`, `DEL`).
- `lib/screens/calendar_screen.dart`: **Tab 2 (Lịch)** - Tổng hợp Thu/Chi/Số dư trong tháng, hiển thị thu chi từng ngày trên lịch tháng và danh sách chi tiết.
- `lib/screens/report_screen.dart`: **Tab 3 (Báo cáo)** - Biểu đồ tròn (`fl_chart`), tỷ lệ phần trăm từng danh mục và thanh theo dõi hạn mức ngân sách tháng.
- `lib/screens/settings_screen.dart`: **Tab 4 (Khác)** - Thêm/sửa danh mục, đặt ngân sách tháng, bật Dark Mode và xuất dữ liệu ra file CSV/Excel.

## Hướng dẫn chạy thử & xuất file lên CH Play

1. **Cài đặt Flutter SDK** (nếu máy bạn chưa cài): Tải tại https://docs.flutter.dev/get-started/install/windows
2. Mở terminal tại thư mục dự án `kakeibo_money_note`:
   ```bash
   # Khởi tạo khung platform Android/iOS (chỉ cần chạy lần đầu nếu chưa có thư mục android/)
   flutter create . --org com.yourname.kakeibo

   # Tải các thư viện
   flutter pub get

   # Chạy ứng dụng trên máy ảo hoặc điện thoại thật
   flutter run
   ```
3. **Xuất file `.aab` để đăng lên Google Play Console:**
   ```bash
   flutter build appbundle --release
   ```
