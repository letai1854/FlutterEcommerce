-- Chú ý:
-- 1. Đảm bảo database của bạn sử dụng collation hỗ trợ tiếng Việt, ví dụ: utf8mb4_unicode_ci.
-- 2. Mật khẩu người dùng (mat_khau) NÊN được lưu trữ dưới dạng hash (vd: bcrypt, Argon2), không bao giờ lưu dạng plain text.
-- 3. Các ràng buộc `ON DELETE`, `ON UPDATE` được đặt là `RESTRICT` hoặc `SET NULL` để tránh mất dữ liệu vô tình. Cân nhắc `CASCADE` cẩn thận nếu cần.
-- 4. Kiểu dữ liệu `DECIMAL(precision, scale)` được sử dụng cho tiền tệ. Điều chỉnh `precision` nếu cần giá trị lớn hơn.
-- 5. Logic nghiệp vụ phức tạp (vd: chỉ user đăng nhập mới được rating, kiểm tra coupon hợp lệ trước khi áp dụng, tính điểm loyalty) nên được xử lý ở tầng ứng dụng.

-- ================= Bảng Danh mục (Categories) =================
CREATE TABLE danh_muc (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ten_danh_muc VARCHAR(255) NOT NULL UNIQUE,
    hinh_anh VARCHAR(255) NULL, -- URL hoặc đường dẫn ảnh
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Thương hiệu (Brands) =================
CREATE TABLE thuong_hieu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ten_thuong_hieu VARCHAR(255) NOT NULL UNIQUE,
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Người dùng (Users) =================
CREATE TABLE nguoi_dung (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    ho_ten VARCHAR(255) NOT NULL,
    mat_khau VARCHAR(255) NOT NULL, -- Lưu dạng hash!
    avatar_url VARCHAR(255) NULL,
    vai_tro ENUM('khach_hang', 'quan_tri') NOT NULL DEFAULT 'khach_hang',
    trang_thai ENUM('kich_hoat', 'khoa') NOT NULL DEFAULT 'kich_hoat',
    diem_khach_hang_than_thiet DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    password_reset_token VARCHAR(255) NULL, -- Thêm cột token reset mật khẩu
    password_reset_token_expiry TIMESTAMP NULL, -- Thêm cột thời gian hết hạn token
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Token Reset Mật khẩu (Password Reset Tokens) =================
CREATE TABLE password_reset_tokens (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    token_hash VARCHAR(255) NOT NULL UNIQUE, -- Changed from 'token' to 'token_hash'
    user_id INT NOT NULL,
    expiry_date TIMESTAMP NOT NULL,
    FOREIGN KEY (user_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Danh sách Địa chỉ (User Addresses) =================
CREATE TABLE danh_sach_dia_chi (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id INT NOT NULL,
    ho_ten_nguoi_nhan VARCHAR(255) NOT NULL,
    so_dien_thoai VARCHAR(15) NOT NULL,
    dia_chi_cu_the TEXT NOT NULL,
    la_mac_dinh BOOLEAN NOT NULL DEFAULT FALSE,
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE ON UPDATE CASCADE -- Xóa địa chỉ nếu user bị xóa
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Sản phẩm (Products) =================
CREATE TABLE san_pham (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ten_san_pham VARCHAR(255) NOT NULL,
    mo_ta TEXT NOT NULL, -- Đảm bảo nhập >= 5 dòng ở application
    danh_muc_id INT NOT NULL,
    thuong_hieu_id INT NOT NULL,
    anh_chinh_url VARCHAR(255) NULL, -- Ảnh đại diện chính
    phan_tram_giam_gia DECIMAL(5, 2) NULL DEFAULT NULL, -- Giảm giá riêng cho SP (vd: 10.50 là 10.5%)
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE, -- Cột cho phép bật/tắt sản phẩm
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (danh_muc_id) REFERENCES danh_muc(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (thuong_hieu_id) REFERENCES thuong_hieu(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    min_price DECIMAL(12, 2) NULL DEFAULT NULL,
    max_price DECIMAL(12, 2) NULL DEFAULT NULL,
    average_rating DOUBLE NULL DEFAULT NULL,
    CHECK (phan_tram_giam_gia IS NULL OR (phan_tram_giam_gia >= 0 AND phan_tram_giam_gia <= 50.00)) -- Giới hạn % giảm giá
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Hình ảnh Sản phẩm (Product Images) =================
-- Lưu trữ nhiều ảnh cho một sản phẩm (yêu cầu >= 3 ảnh)
CREATE TABLE hinh_anh_san_pham (
    id INT AUTO_INCREMENT PRIMARY KEY,
    san_pham_id INT NOT NULL,
    url_hinh_anh VARCHAR(255) NOT NULL,
    -- la_anh_chinh BOOLEAN NOT NULL DEFAULT FALSE, -- Có thể dùng trường này hoặc dựa vào `san_pham.anh_chinh_url`
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (san_pham_id) REFERENCES san_pham(id) ON DELETE CASCADE ON UPDATE CASCADE -- Xóa ảnh nếu sản phẩm bị xóa
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ================= Bảng Biến thể Sản phẩm (Product Variants) =================
-- Bảng quan trọng nhất: Mỗi sản phẩm có ít nhất 2 biến thể, quản lý giá và tồn kho riêng
CREATE TABLE bien_the_san_pham (
    id INT AUTO_INCREMENT PRIMARY KEY,
    san_pham_id INT NOT NULL,
    ten_bien_the VARCHAR(255) NOT NULL, -- Ví dụ: "Màu Đen, RAM 16GB, SSD 512GB"
    sku VARCHAR(100) UNIQUE NULL, -- Mã SKU (Stock Keeping Unit) nếu cần
    gia DECIMAL(12, 2) NOT NULL, -- Giá của biến thể này
    phan_tram_giam_gia DECIMAL(5, 2) NULL DEFAULT NULL, -- Giảm giá riêng cho biến thể (vd: 10.50 là 10.5%)
    so_luong_ton_kho INT NOT NULL DEFAULT 0,
    hinh_anh_bien_the_url VARCHAR(255) NULL, -- Ảnh riêng cho biến thể nếu có
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (san_pham_id) REFERENCES san_pham(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Xóa biến thể nếu sản phẩm bị xóa
    CHECK (phan_tram_giam_gia IS NULL OR (phan_tram_giam_gia >= 0 AND phan_tram_giam_gia <= 50.00)) -- Giới hạn % giảm giá
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Giỏ hàng (Cart) =================
CREATE TABLE gio_hang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id INT NULL, -- NULL cho khách vãng lai
    session_id VARCHAR(255) NULL, -- Lưu session ID cho khách vãng lai
    bien_the_san_pham_id INT NOT NULL,
    so_luong INT NOT NULL DEFAULT 1,
    ngay_them_vao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (bien_the_san_pham_id) REFERENCES bien_the_san_pham(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CHECK (nguoi_dung_id IS NOT NULL OR session_id IS NOT NULL), -- Phải thuộc về user hoặc session
    CHECK (so_luong > 0),
    -- Ràng buộc UNIQUE để tránh trùng lặp item trong giỏ của cùng user/session
    UNIQUE KEY unique_user_cart_item (nguoi_dung_id, bien_the_san_pham_id),
    UNIQUE KEY unique_session_cart_item (session_id, bien_the_san_pham_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Mã giảm giá (Coupons) =================
CREATE TABLE ma_giam_gia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ma_code VARCHAR(10) NOT NULL UNIQUE, -- Mã gồm 5 ký tự chữ và số (đặt ràng buộc độ dài ở app)
    gia_tri_giam DECIMAL(12, 2) NOT NULL, -- Số tiền giảm cố định (vd: 10000, 20000, 50000, 100000)
    so_lan_su_dung_toi_da INT NOT NULL DEFAULT 10, -- Giới hạn sử dụng (yêu cầu <= 10)
    so_lan_da_su_dung INT NOT NULL DEFAULT 0,
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    -- ngay_het_han TIMESTAMP NULL, -- Yêu cầu không có ngày hết hạn
    CHECK (so_lan_da_su_dung <= so_lan_su_dung_toi_da),
    CHECK (gia_tri_giam > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Đơn hàng (Orders) =================
CREATE TABLE don_hang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id INT NOT NULL, -- ID của người dùng (tài khoản tự tạo cho khách)
    ma_giam_gia_id INT NULL, -- Mã giảm giá đã áp dụng (nếu có)

    -- Thông tin người nhận (lưu snapshot tại thời điểm đặt hàng)
    ten_nguoi_nhan VARCHAR(255) NOT NULL,
    so_dien_thoai_nguoi_nhan VARCHAR(15) NOT NULL,
    dia_chi_giao_hang TEXT NOT NULL,

    -- Giá trị đơn hàng
    tong_tien_hang_goc DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Tổng tiền các sản phẩm chưa giảm giá
    tien_giam_gia_coupon DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Số tiền giảm từ coupon
    tien_su_dung_diem DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Số tiền giảm từ điểm loyalty
    phi_van_chuyen DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    thue DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Nếu có
    tong_thanh_toan DECIMAL(12, 2) NOT NULL DEFAULT 0.00, -- Số tiền cuối cùng khách phải trả

    -- Thanh toán và Trạng thái
    phuong_thuc_thanh_toan VARCHAR(50) NULL,
    trang_thai_thanh_toan ENUM('chua_thanh_toan', 'da_thanh_toan', 'loi_thanh_toan') NOT NULL DEFAULT 'chua_thanh_toan',
    trang_thai_don_hang ENUM('cho_xu_ly', 'da_xac_nhan', 'dang_giao', 'da_giao', 'da_huy') NOT NULL DEFAULT 'cho_xu_ly',

    -- Loyalty
    diem_tich_luy DECIMAL(10, 2) NOT NULL DEFAULT 0.00, -- Điểm kiếm được từ đơn hàng này

    ngay_dat_hang TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ma_giam_gia_id) REFERENCES ma_giam_gia(id) ON DELETE SET NULL ON UPDATE CASCADE -- Nếu mã bị xóa, đơn hàng vẫn giữ lại thông tin tiền giảm
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Chi tiết Đơn hàng (Order Details) =================
CREATE TABLE chi_tiet_don_hang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    don_hang_id INT NOT NULL,
    bien_the_san_pham_id INT NOT NULL,
    so_luong INT NOT NULL,
    gia_tai_thoi_diem_mua DECIMAL(12, 2) NOT NULL, -- Giá của 1 biến thể lúc mua
    phan_tram_giam_gia_san_pham DECIMAL(5, 2) NULL DEFAULT NULL, -- % giảm giá SP lúc mua (nếu có)
    thanh_tien DECIMAL(12,2) NOT NULL, -- Tiền sau khi áp dụng giảm giá SP (gia * soluong * (1-giamgia/100))

    FOREIGN KEY (don_hang_id) REFERENCES don_hang(id) ON DELETE CASCADE ON UPDATE CASCADE, -- Xóa chi tiết nếu đơn hàng bị xóa
    FOREIGN KEY (bien_the_san_pham_id) REFERENCES bien_the_san_pham(id) ON DELETE RESTRICT ON UPDATE CASCADE, -- Không cho xóa biến thể nếu còn trong đơn hàng
    UNIQUE KEY unique_order_variant (don_hang_id, bien_the_san_pham_id), -- Mỗi biến thể chỉ xuất hiện 1 lần/đơn hàng
    CHECK (so_luong > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Lịch sử Trạng thái Đơn hàng (Order Status History) =================
CREATE TABLE lich_su_trang_thai_don_hang (
    id INT AUTO_INCREMENT PRIMARY KEY,
    don_hang_id INT NOT NULL,
    trang_thai ENUM('cho_xu_ly', 'da_xac_nhan', 'dang_giao', 'da_giao', 'da_huy') NOT NULL,
    ghi_chu TEXT NULL, -- Ghi chú thêm nếu cần (vd: lý do hủy)
    thoi_gian_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (don_hang_id) REFERENCES don_hang(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Đánh giá Sản phẩm (Product Reviews/Ratings) =================
-- Gộp bình luận và đánh giá sao
CREATE TABLE danh_gia_san_pham (
    id INT AUTO_INCREMENT PRIMARY KEY,
    san_pham_id INT NOT NULL,
    nguoi_dung_id INT NULL, -- NULL nếu là bình luận ẩn danh (khách)
    ten_nguoi_danh_gia_an_danh VARCHAR(100) NULL, -- Tên khách nhập khi bình luận ẩn danh
    diem_sao TINYINT NULL, -- 1-5 sao, NULL nếu chỉ bình luận (chỉ user đăng nhập mới được set giá trị này - logic app)
    binh_luan TEXT NULL, -- Nội dung bình luận, NULL nếu chỉ đánh giá sao
    thoi_gian_danh_gia TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (san_pham_id) REFERENCES san_pham(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE SET NULL ON UPDATE CASCADE, -- Giữ lại đánh giá nếu user bị xóa, chỉ mất liên kết
    CHECK (diem_sao IS NULL OR diem_sao BETWEEN 1 AND 5),
    CHECK (nguoi_dung_id IS NOT NULL OR ten_nguoi_danh_gia_an_danh IS NOT NULL), -- Phải có thông tin người đánh giá
    CHECK (diem_sao IS NOT NULL OR binh_luan IS NOT NULL) -- Phải có ít nhất sao hoặc bình luận
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Cuộc hội thoại Hỗ trợ (Support Conversations) =================
CREATE TABLE cuoc_hoi_thoai (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nguoi_dung_id INT NOT NULL, -- Khách hàng bắt đầu chat
    tieu_de VARCHAR(255) NULL, -- Chủ đề cuộc chat (nếu có)
    trang_thai ENUM('moi', 'dang_xu_ly', 'da_dong') NOT NULL DEFAULT 'moi',
    ngay_tao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ngay_cap_nhat TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (nguoi_dung_id) REFERENCES nguoi_dung(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================= Bảng Tin nhắn Hỗ trợ (Support Messages) =================
CREATE TABLE tin_nhan (
    id INT AUTO_INCREMENT PRIMARY KEY,
    cuoc_hoi_thoai_id INT NOT NULL,
    nguoi_gui_id INT NOT NULL, -- ID của người dùng (khách hoặc admin)
    noi_dung TEXT NULL, -- Nội dung text
    url_hinh_anh VARCHAR(255) NULL, -- URL ảnh nếu gửi ảnh
    thoi_gian_gui TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cuoc_hoi_thoai_id) REFERENCES cuoc_hoi_thoai(id) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (nguoi_gui_id) REFERENCES nguoi_dung(id) ON DELETE RESTRICT ON UPDATE CASCADE, -- Không cho xóa user nếu còn tin nhắn
    CHECK (noi_dung IS NOT NULL OR url_hinh_anh IS NOT NULL) -- Phải có text hoặc ảnh
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Thêm Index cho các cột thường xuyên được sử dụng trong WHERE, JOIN để tăng tốc độ truy vấn
CREATE INDEX idx_sp_danhmuc ON san_pham(danh_muc_id);
CREATE INDEX idx_sp_thuonghieu ON san_pham(thuong_hieu_id);
CREATE INDEX idx_btsp_sanpham ON bien_the_san_pham(san_pham_id);
CREATE INDEX idx_gh_user ON gio_hang(nguoi_dung_id);
CREATE INDEX idx_gh_session ON gio_hang(session_id);
CREATE INDEX idx_dh_user ON don_hang(nguoi_dung_id);
CREATE INDEX idx_dh_trangthai ON don_hang(trang_thai_don_hang);
CREATE INDEX idx_ctdh_donhang ON chi_tiet_don_hang(don_hang_id);
CREATE INDEX idx_ctdh_bienthe ON chi_tiet_don_hang(bien_the_san_pham_id);
CREATE INDEX idx_dgsp_sanpham ON danh_gia_san_pham(san_pham_id);
CREATE INDEX idx_dgsp_user ON danh_gia_san_pham(nguoi_dung_id);
CREATE INDEX idx_tn_cuochoithoai ON tin_nhan(cuoc_hoi_thoai_id);
CREATE INDEX idx_sp_min_price ON san_pham(min_price);
CREATE INDEX idx_sp_max_price ON san_pham(max_price);
CREATE INDEX idx_sp_avg_rating ON san_pham(average_rating);
CREATE INDEX idx_sp_created_date ON san_pham(ngay_tao); -- Thêm nếu chưa có và thường xuyên sắp xếp theo ngày tạo