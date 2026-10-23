# Super Productivity Pomodoro Widget for KDE Plasma 6

KDE Plasma 6 Widget giúp theo dõi và đồng bộ Pomodoro / Task tracking từ Super Productivity lên thanh KDE Bar.

## Tính năng
- **Hiển thị trực tiếp trên KDE Panel**: Đồng hồ đếm ngược `mm:ss`, trạng thái phiên (Focusing / Short Break / Long Break), tên task đang làm.
- **Biểu tượng trạng thái thông minh**: Tự đổi icon theo trạng thái (nghỉ ngơi / làm việc / dừng).
- **Popup chi tiết**: Nhấp chuột trái để xem số vòng lặp (Cycle #), thời gian đếm ngược cỡ lớn, nút **Stop Task** và nút mở nhanh app (**Open App**).
- **Middle Click (Chuột giữa)**: Nhấp chuột giữa vào widget trên thanh bar để focus/mở ngay cửa sổ Super Productivity.
- **Không thay đổi mã nguồn app**: Sử dụng 100% Local REST API chuẩn sẵn có của Super Productivity.

## Cài đặt & Kích hoạt

### 1. Bật Local REST API trong Super Productivity
1. Mở Super Productivity.
2. Vào **Settings** -> **Miscellaneous** -> bật **Local REST API**.
3. (Tùy chọn) Chọn port mặc định là `3876`. Token xác thực sẽ tự động được lưu an toàn tại `~/.config/superProductivity/local-rest-api-token`.

### 2. Cài đặt Widget vào KDE Plasma
Widget đã được symlink vào thư mục Plasmoid của user:
```bash
ln -sfn /path/to/super-productivity/extra/kde-plasma-widget/org.kde.plasma.superproductivity ~/.local/share/plasma/plasmoids/org.kde.plasma.superproductivity
```

### 3. Thêm Widget vào Panel / Bar KDE
1. Nhấp chuột phải vào thanh Taskbar/Panel của KDE -> chọn **Enter Edit Mode** (Chế độ chỉnh sửa).
2. Bấm **Add Widgets...** (Thêm tiện ích).
3. Tìm kiếm **Super Productivity Pomodoro**.
4. Kéo thả widget vào vị trí mong muốn trên Panel.
