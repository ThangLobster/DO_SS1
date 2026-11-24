#!/bin/bash
# ============================================================
# deploy-local.sh
# Script triển khai tự động "Một chạm" cho QuickBite user-service
# Áp dụng triết lý Fail-fast: dừng ngay khi phát hiện lỗi
# ============================================================

set -e  # Bật Fail-fast mode toàn cục

# ===================== CẤU HÌNH =====================
APP_NAME="user-service"
APP_VERSION="0.0.1"
JAR_NAME="${APP_NAME}-${APP_VERSION}.jar"
SOURCE_DIR="/home/$USER/quickbite/${APP_NAME}"
DEPLOY_DIR="/opt/quickbite"
DEPLOY_JAR="${DEPLOY_DIR}/${JAR_NAME}"
SERVICE_USER="quickbite"
SERVICE_GROUP="quickbite"
SERVICE_PORT=8080
LOG_FILE="${DEPLOY_DIR}/${APP_NAME}.log"
SLEEP_SECONDS=5

# ===================== MÀU SẮC ANSI =====================
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ===================== HÀM TIỆN ÍCH =====================

# In banner bước với màu sắc
print_step() {
    local step_num=$1
    local step_desc=$2
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  [Bước ${step_num}/5]${NC} ${BOLD}${step_desc}${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# In thông báo thành công
print_success() {
    echo -e "  ${GREEN}✔ $1${NC}"
}

# In thông báo lỗi và thoát
print_error_and_exit() {
    echo -e "  ${RED}✘ LỖI: $1${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  DEPLOY THẤT BẠI! Script dừng lại.      ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
}

# In thông tin
print_info() {
    echo -e "  ${YELLOW}→ $1${NC}"
}

# ===================== BẮT ĐẦU DEPLOY =====================

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║                                              ║"
echo "║   🚀 QuickBite - Automated Local Deploy     ║"
echo "║      One-Click Deployment Script             ║"
echo "║                                              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ===========================================================
# BƯỚC 1: BIÊN DỊCH MÃ NGUỒN (Build & Test) - FAIL-FAST
# ===========================================================
print_step "1" "Biên dịch mã nguồn (Build & Test)"

print_info "Di chuyển vào thư mục source code: ${SOURCE_DIR}"

if [ ! -d "${SOURCE_DIR}" ]; then
    print_error_and_exit "Thư mục source code không tồn tại: ${SOURCE_DIR}"
fi

cd "${SOURCE_DIR}"
print_info "Chạy lệnh build: ./gradlew clean bootJar"

# Thực hiện build và kiểm tra exit code (Fail-fast)
if ! ./gradlew clean bootJar; then
    print_error_and_exit "Build THẤT BẠI! Kiểm tra lại mã nguồn Java."
fi

# Kiểm tra file JAR đã được tạo
BUILD_JAR=$(find "${SOURCE_DIR}/build/libs" -name "*.jar" -not -name "*-plain.jar" | head -1)
if [ -z "${BUILD_JAR}" ]; then
    print_error_and_exit "Không tìm thấy file JAR sau khi build!"
fi

print_success "Build thành công! File JAR: ${BUILD_JAR}"

# ===========================================================
# BƯỚC 2: CHUẨN BỊ HẠ TẦNG THƯ MỤC
# ===========================================================
print_step "2" "Chuẩn bị hạ tầng thư mục"

if [ ! -d "${DEPLOY_DIR}/${APP_NAME}" ]; then
    print_info "Thư mục chưa tồn tại, đang tạo mới..."
    sudo mkdir -p "${DEPLOY_DIR}/${APP_NAME}"
    sudo chown -R ${SERVICE_USER}:${SERVICE_GROUP} "${DEPLOY_DIR}"
    sudo chmod -R 750 "${DEPLOY_DIR}"
    print_success "Đã tạo và phân quyền thư mục ${DEPLOY_DIR}/${APP_NAME}"
else
    print_success "Thư mục ${DEPLOY_DIR}/${APP_NAME} đã tồn tại"
fi

# ===========================================================
# BƯỚC 3: SAO CHÉP ỨNG DỤNG
# ===========================================================
print_step "3" "Sao chép ứng dụng mới"

# Dừng tiến trình dịch vụ cũ (nếu có)
print_info "Kiểm tra tiến trình dịch vụ cũ trên cổng ${SERVICE_PORT}..."
OLD_PID=$(sudo ss -tulpn | grep ":${SERVICE_PORT}" | awk '{print $NF}' | grep -oP 'pid=\K[0-9]+' || true)

if [ -n "${OLD_PID}" ]; then
    print_info "Phát hiện tiến trình cũ PID=${OLD_PID}, đang dừng..."
    sudo kill -15 ${OLD_PID} 2>/dev/null || true
    sleep 2
    # Nếu vẫn chạy, buộc tắt
    if kill -0 ${OLD_PID} 2>/dev/null; then
        sudo kill -9 ${OLD_PID} 2>/dev/null || true
        print_info "Đã buộc tắt tiến trình cũ (SIGKILL)"
    else
        print_success "Đã dừng tiến trình cũ thành công (SIGTERM)"
    fi
else
    print_info "Không có tiến trình cũ đang chạy"
fi

# Sao chép file JAR mới
print_info "Sao chép file JAR mới vào ${DEPLOY_JAR}..."
sudo cp "${BUILD_JAR}" "${DEPLOY_JAR}"
sudo chown ${SERVICE_USER}:${SERVICE_GROUP} "${DEPLOY_JAR}"
sudo chmod 750 "${DEPLOY_JAR}"

print_success "Đã sao chép và phân quyền file JAR"

# ===========================================================
# BƯỚC 4: KHỞI ĐỘNG DỊCH VỤ
# ===========================================================
print_step "4" "Khởi động dịch vụ ${APP_NAME}"

print_info "Khởi chạy JAR dưới quyền user ${SERVICE_USER}..."

# Khởi chạy dưới dạng tiến trình ngầm bằng nohup với user quickbite
sudo -u ${SERVICE_USER} nohup java -jar "${DEPLOY_JAR}" \
    --server.port=${SERVICE_PORT} \
    > "${LOG_FILE}" 2>&1 &

NEW_PID=$!
print_success "Dịch vụ đã khởi chạy với PID=${NEW_PID}"

# ===========================================================
# BƯỚC 5: SMOKE TEST
# ===========================================================
print_step "5" "Smoke Test - Kiểm tra trạng thái dịch vụ"

print_info "Chờ ${SLEEP_SECONDS} giây để JVM khởi tạo..."
sleep ${SLEEP_SECONDS}

# Kiểm tra cổng 8080 đã mở chưa
if sudo ss -tulpn | grep -q ":${SERVICE_PORT}"; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                              ║${NC}"
    echo -e "${GREEN}║   ✅ DEPLOY DỊCH VỤ THÀNH CÔNG!             ║${NC}"
    echo -e "${GREEN}║                                              ║${NC}"
    echo -e "${GREEN}║   Service : ${APP_NAME}                      ║${NC}"
    echo -e "${GREEN}║   Port    : ${SERVICE_PORT}                          ║${NC}"
    echo -e "${GREEN}║   JAR     : ${JAR_NAME}        ║${NC}"
    echo -e "${GREEN}║   User    : ${SERVICE_USER}                      ║${NC}"
    echo -e "${GREEN}║   Log     : ${LOG_FILE}       ║${NC}"
    echo -e "${GREEN}║                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    print_success "Dịch vụ đang lắng nghe trên cổng ${SERVICE_PORT}"

    # Thử gọi health check (nếu có endpoint)
    print_info "Thử gọi health check..."
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${SERVICE_PORT}/actuator/health 2>/dev/null || echo "000")
    if [ "${HTTP_CODE}" = "200" ]; then
        print_success "Health check: HTTP ${HTTP_CODE} - Ứng dụng hoạt động bình thường"
    else
        print_info "Health check: HTTP ${HTTP_CODE} - Ứng dụng đang khởi tạo hoặc không có endpoint /actuator/health"
    fi
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                                              ║${NC}"
    echo -e "${RED}║   ❌ DEPLOY THẤT BẠI!                        ║${NC}"
    echo -e "${RED}║   Cổng ${SERVICE_PORT} không mở sau ${SLEEP_SECONDS}s           ║${NC}"
    echo -e "${RED}║                                              ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    print_error_msg="Dịch vụ không khởi động được. Trích xuất 30 dòng log cuối:"
    echo -e "  ${RED}✘ ${print_error_msg}${NC}"
    echo -e "${YELLOW}──────────── LOG OUTPUT ────────────${NC}"

    if [ -f "${LOG_FILE}" ]; then
        tail -30 "${LOG_FILE}"
    else
        echo "  (Không tìm thấy file log tại ${LOG_FILE})"
    fi

    echo -e "${YELLOW}────────────────────────────────────${NC}"
    exit 1
fi
