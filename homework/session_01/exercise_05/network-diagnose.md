# Báo cáo chẩn đoán mạng - QuickBite DevOps

## Tình huống 1: Xử lý trùng cổng 8080 (Address already in use)

### Mô tả vấn đề
Ứng dụng `user-service` khi khởi chạy báo lỗi:
```
***************************
APPLICATION FAILED TO START
***************************
Description: Web server failed to start. Port 8080 was already in use.
Action: Identify and stop the process that's listening on port 8080
```

### Các bước xử lý

#### Bước 1: Tìm tiến trình đang chiếm cổng 8080

```bash
sudo ss -tulpn | grep :8080
```

**Giải thích lệnh `ss -tulpn`:**
| Cờ (Flag) | Ý nghĩa |
|-----------|----------|
| `-t` | Hiển thị kết nối TCP |
| `-u` | Hiển thị kết nối UDP |
| `-l` | Chỉ hiển thị các socket đang lắng nghe (LISTEN) |
| `-p` | Hiển thị tên tiến trình (process) đang sử dụng socket |
| `-n` | Hiển thị số cổng thay vì tên dịch vụ (ví dụ: 8080 thay vì http-alt) |

**Kết quả mẫu:**
```
LISTEN  0  4096  *:8080  *:*  users:(("java",pid=12345,fd=15))
```

→ Tiến trình `java` với **PID = 12345** đang chiếm cổng 8080.

#### Bước 2: Dừng tiến trình chiếm cổng

```bash
sudo kill -9 12345
```

**Giải thích:**
- `kill` : Gửi tín hiệu (signal) tới tiến trình
- `-9` : Tín hiệu `SIGKILL` - buộc tắt ngay lập tức, không cho tiến trình dọn dẹp
- `12345` : PID của tiến trình cần tắt

> **Lưu ý:** Nên thử `kill -15 <PID>` (SIGTERM - dừng nhẹ nhàng) trước. Chỉ dùng `kill -9` khi tiến trình không phản hồi SIGTERM.

#### Bước 3: Xác nhận cổng đã được giải phóng

```bash
sudo ss -tulpn | grep :8080
```

**Kết quả mong đợi:** Không có dòng nào được in ra → cổng 8080 đã được giải phóng thành công.

#### Lệnh tắt gọn (One-liner) - Tìm và kill tự động:

```bash
sudo kill -9 $(sudo ss -tulpn | grep :8080 | awk '{print $NF}' | grep -oP 'pid=\K[0-9]+')
```

---

## Tình huống 2: Chẩn đoán kết nối Database PostgreSQL (10.0.1.20:5432)

### Mô tả vấn đề
Ứng dụng báo lỗi không kết nối được tới Database PostgreSQL:
```
org.postgresql.util.PSQLException: Connection to 10.0.1.20:5432 refused.
```

### Các bước chẩn đoán

#### Bước 1: Kiểm tra kết nối vật lý (ping)

```bash
ping -c 4 10.0.1.20
```

**Giải thích:**
- `ping` : Gửi gói ICMP Echo Request để kiểm tra xem máy chủ đích có phản hồi hay không
- `-c 4` : Gửi 4 gói tin rồi dừng (nếu không có `-c`, ping sẽ chạy vô hạn trên Linux)

**Kết quả thành công (máy chủ phản hồi):**
```
PING 10.0.1.20 (10.0.1.20) 56(84) bytes of data.
64 bytes from 10.0.1.20: icmp_seq=1 ttl=64 time=0.523 ms
64 bytes from 10.0.1.20: icmp_seq=2 ttl=64 time=0.412 ms
...
4 packets transmitted, 4 received, 0% packet loss
```

**Kết quả thất bại (không thể kết nối):**
```
PING 10.0.1.20 (10.0.1.20) 56(84) bytes of data.
...
4 packets transmitted, 0 received, 100% packet loss
```
→ **Nguyên nhân có thể:** Máy chủ DB tắt, sai IP, firewall chặn ICMP, hoặc không cùng mạng.

#### Bước 2: Kiểm tra cổng 5432 có mở hay không

**Cách 1: Sử dụng `nc` (netcat)**

```bash
nc -zv 10.0.1.20 5432
```

**Giải thích:**
- `nc` (netcat) : Công cụ kiểm tra kết nối TCP/UDP
- `-z` : Chế độ scan - chỉ kiểm tra cổng có mở không, không gửi dữ liệu
- `-v` : Verbose - hiển thị chi tiết kết quả

**Kết quả thành công:**
```
Connection to 10.0.1.20 5432 port [tcp/postgresql] succeeded!
```

**Kết quả thất bại:**
```
nc: connect to 10.0.1.20 port 5432 (tcp) failed: Connection refused
```

**Cách 2: Sử dụng `curl -v`**

```bash
curl -v telnet://10.0.1.20:5432
```

**Giải thích:**
- `curl -v` : Thực hiện kết nối ở chế độ verbose
- `telnet://` : Sử dụng giao thức telnet để thử mở kết nối TCP tới cổng chỉ định

**Kết quả thành công:**
```
* Connected to 10.0.1.20 (10.0.1.20) port 5432 (#0)
```

**Kết quả thất bại:**
```
* Failed to connect to 10.0.1.20 port 5432: Connection refused
```

#### Bước 3: Kiểm tra route mạng (nếu cần)

```bash
traceroute 10.0.1.20
```

**Giải thích:** Hiển thị đường đi (route) của gói tin từ máy hiện tại đến máy chủ đích, giúp xác định gói tin bị nghẽn ở hop nào.

---

## Tổng kết các lệnh sử dụng

| Lệnh | Mục đích |
|-------|----------|
| `sudo ss -tulpn \| grep :8080` | Tìm tiến trình đang chiếm cổng 8080 |
| `sudo kill -9 <PID>` | Buộc tắt tiến trình theo PID |
| `ping -c 4 10.0.1.20` | Kiểm tra kết nối vật lý tới máy chủ DB |
| `nc -zv 10.0.1.20 5432` | Kiểm tra cổng PostgreSQL 5432 có mở hay không |
| `curl -v telnet://10.0.1.20:5432` | Kiểm tra kết nối TCP tới cổng DB |
| `traceroute 10.0.1.20` | Truy vết đường đi gói tin tới máy chủ DB |
