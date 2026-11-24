#!/bin/bash
# ============================================================
# initial-script.sh
# Script cài đặt ban đầu và tạo user/group tự động cho QuickBite
# ============================================================

set -e  # Fail-fast: dừng script ngay khi có lệnh lỗi

# --- Màu sắc cho output ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  QuickBite - Initial Setup Script      ${NC}"
echo -e "${BLUE}========================================${NC}"

# ----------------------------------------------------------
# Bước 1: Cập nhật hệ thống
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 1/4]${NC} Cập nhật hệ thống..."
sudo apt-get update && sudo apt-get upgrade -y
echo -e "${GREEN}✔ Cập nhật hệ thống thành công!${NC}"

# ----------------------------------------------------------
# Bước 2: Cài đặt các gói phần mềm bắt buộc
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 2/4]${NC} Cài đặt openjdk-17-jdk, git, curl..."
sudo apt-get install -y openjdk-17-jdk git curl
echo -e "${GREEN}✔ Cài đặt gói phần mềm thành công!${NC}"

# Xác nhận phiên bản Java
java -version 2>&1 | head -1
echo -e "${GREEN}✔ Java 17 đã sẵn sàng.${NC}"

# ----------------------------------------------------------
# Bước 3: Kiểm tra và tạo group quickbite
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 3/4]${NC} Kiểm tra nhóm 'quickbite'..."
if getent group quickbite > /dev/null 2>&1; then
    echo -e "${GREEN}✔ Nhóm 'quickbite' đã tồn tại, bỏ qua.${NC}"
else
    sudo groupadd quickbite
    echo -e "${GREEN}✔ Đã tạo nhóm 'quickbite' thành công!${NC}"
fi

# ----------------------------------------------------------
# Bước 4: Tạo system user quickbite
# ----------------------------------------------------------
echo -e "\n${YELLOW}[Bước 4/4]${NC} Tạo system user 'quickbite'..."
if id quickbite > /dev/null 2>&1; then
    echo -e "${GREEN}✔ User 'quickbite' đã tồn tại, bỏ qua.${NC}"
else
    # -r : tạo system user (không tạo thư mục home)
    # -g quickbite : thuộc nhóm quickbite
    # -s /bin/false : khóa quyền đăng nhập trực tiếp
    sudo useradd -r -g quickbite -s /bin/false quickbite
    echo -e "${GREEN}✔ Đã tạo system user 'quickbite' thành công!${NC}"
fi

# ----------------------------------------------------------
# Xác nhận kết quả
# ----------------------------------------------------------
echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}  Kết quả xác nhận                      ${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}Thông tin user quickbite:${NC}"
id quickbite

echo -e "\n${YELLOW}Cấu hình login shell:${NC}"
getent passwd | grep quickbite

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  KHỞI TẠO MÔI TRƯỜNG THÀNH CÔNG!      ${NC}"
echo -e "${GREEN}========================================${NC}"
