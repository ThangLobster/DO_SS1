#!/bin/bash
# ============================================================
# setup-dirs.sh
# Thiết lập thư mục ứng dụng và phân quyền sở hữu tối giản
# cho QuickBite user-service
# ============================================================

set -e  # Fail-fast

# --- Màu sắc cho output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  QuickBite - Directory Setup Script    ${NC}"
echo -e "${BLUE}========================================${NC}"

# ----------------------------------------------------------
# Bước 1: Tạo thư mục làm việc của dự án
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 1/3]${NC} Tạo thư mục /opt/quickbite/user-service..."

sudo mkdir -p /opt/quickbite/user-service

echo -e "${GREEN}✔ Đã tạo thư mục /opt/quickbite/user-service${NC}"

# ----------------------------------------------------------
# Bước 2: Thay đổi chủ sở hữu (chown)
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 2/3]${NC} Thay đổi chủ sở hữu cho user/group quickbite..."

# -R : áp dụng đệ quy cho toàn bộ thư mục con bên trong
sudo chown -R quickbite:quickbite /opt/quickbite

echo -e "${GREEN}✔ Đã đổi chủ sở hữu toàn bộ /opt/quickbite → quickbite:quickbite${NC}"

# ----------------------------------------------------------
# Bước 3: Phân quyền truy cập 750
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 3/3]${NC} Đặt quyền truy cập 750 cho /opt/quickbite..."

sudo chmod -R 750 /opt/quickbite

echo -e "${GREEN}✔ Đã đặt quyền 750 cho /opt/quickbite${NC}"

# ----------------------------------------------------------
# Giải thích ý nghĩa mã phân quyền 750
# ----------------------------------------------------------
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Giải thích quyền 750 (rwxr-x---)      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "
  ${YELLOW}7${NC} (rwx) - Owner (quickbite):
      ├── r (4): Quyền đọc (read) - xem nội dung file/thư mục
      ├── w (2): Quyền ghi (write) - tạo, sửa, xóa file
      └── x (1): Quyền thực thi (execute) - chạy file/truy cập thư mục

  ${YELLOW}5${NC} (r-x) - Group (quickbite):
      ├── r (4): Quyền đọc - xem nội dung
      ├── - (0): KHÔNG có quyền ghi
      └── x (1): Quyền thực thi - truy cập thư mục

  ${YELLOW}0${NC} (---) - Others (người dùng khác):
      ├── - (0): KHÔNG có quyền đọc
      ├── - (0): KHÔNG có quyền ghi
      └── - (0): KHÔNG có quyền thực thi

  → Nguyên tắc Least Privilege: Chỉ owner có toàn quyền,
    thành viên group chỉ đọc/thực thi, người ngoài bị chặn hoàn toàn.
    Điều này bảo vệ file cấu hình chứa thông tin nhạy cảm (DB password,
    API keys...) khỏi bị người dùng không liên quan đọc được.
"

# ----------------------------------------------------------
# Xác nhận kết quả
# ----------------------------------------------------------
echo -e "${YELLOW}Kiểm tra phân quyền thư mục:${NC}"
ls -la /opt | grep quickbite

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  THIẾT LẬP THƯ MỤC THÀNH CÔNG!        ${NC}"
echo -e "${GREEN}========================================${NC}"
