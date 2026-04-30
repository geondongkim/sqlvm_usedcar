# 🏗️ Architecture — SQL VM Used Car

## 1. 시스템 구성도

```
┌──────────────────────────────────────────────────────────┐
│  Local PC                                                 │
│   ├── 브라우저 (Chrome/Edge)                               │
│   ├── Azure CLI (인프라 프로비저닝)                         │
│   └── SSH Client (VM 운영)                                 │
└──────────────────────────┬───────────────────────────────┘
                           │ HTTP :5000 / SSH :22
                           │
                  ┌────────▼────────┐
                  │ Standard PIP    │  ◄── NSG (DB-VM-NSG)
                  │ (Static)        │      • inbound 22  (SSH)
                  └────────┬────────┘      • inbound 5000 (HTTP)
                           │              • inbound 1433 ✗ 차단
                           │
┌──────────────────────────▼───────────────────────────────┐
│ Azure VM  (Ubuntu 24.04 LTS, Standard_B2s, P10 Premium)  │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │ systemd: carmarket.service                       │    │
│  │   └── gunicorn (workers=2, bind 0.0.0.0:5000)    │    │
│  │         └── Flask app (app:app)                  │    │
│  │               └── pyodbc (ODBC Driver 18)        │    │
│  └─────────────────┬────────────────────────────────┘    │
│                    │ TCP :1433 (loopback only)           │
│  ┌─────────────────▼────────────────────────────────┐    │
│  │ mssql-server.service                             │    │
│  │   └── SQL Server 2025 Developer                  │    │
│  │         bind: 127.0.0.1:1433                     │    │
│  │         DB:   CarMarket                          │    │
│  │           ├── Users      (5 rows seed)           │    │
│  │           ├── Cars       (5 rows seed)           │    │
│  │           └── Inquiries  (0 rows)                │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  Storage:                                                │
│   ├── OS Disk: Premium SSD P10 (32 GB)                   │
│   └── Swap: /swapfile 2 GB                               │
└──────────────────────────────────────────────────────────┘
```

## 2. 데이터 모델 (ERD)

```
┌─────────────────┐         ┌──────────────────────┐
│     Users       │ 1     N │        Cars          │
├─────────────────┤◄────────┤──────────────────────┤
│ UserId    PK    │ SellerId│ CarId       PK       │
│ Name            │   FK    │ SellerId    FK       │
│ Email   UNIQUE  │         │ Brand                │
│ Phone           │         │ Model                │
│ UserType  (chk) │         │ Year                 │
│ CreatedAt       │         │ Price                │
└─────────────────┘         │ Mileage              │
       ▲                    │ FuelType             │
       │ 1                  │ Description          │
       │                    │ Status      (chk)    │
       │ N (BuyerId)        │ CreatedAt            │
       │                    └──────────┬───────────┘
       │                               │ 1
       │                               │
       │     ┌─────────────────────────▼─┐
       └─────┤      Inquiries          N │
             ├───────────────────────────┤
             │ InquiryId   PK            │
             │ CarId       FK            │
             │ BuyerId     FK            │
             │ Message                   │
             │ CreatedAt                 │
             └───────────────────────────┘

Indexes on Cars:
  • IX_Cars_Brand     (b-tree, non-clustered)
  • IX_Cars_Status    (b-tree, non-clustered)
  • IX_Cars_CreatedAt (b-tree, non-clustered, DESC)
```

## 3. API 명세

| Method | Endpoint | 설명 | 응답 |
|---|---|---|---|
| GET  | `/health`         | DB 연결 상태 | `{"status":"ok","db":"connected"}` |
| GET  | `/api/users`      | 사용자 목록 | `[{id, name, email, phone, type}]` |
| GET  | `/api/cars`       | 차량 목록(필터: `brand`, `max_price`) | `[{id, seller, brand, model, year, price, ...}]` |
| POST | `/api/cars`       | 매물 등록 | `{"car_id": 6}` |
| POST | `/api/inquiries`  | 문의 등록 | `{"inquiry_id": 1}` |

### POST 요청 예시

**매물 등록**
```json
{
  "seller_id": 1,
  "brand": "기아",
  "model": "카니발",
  "year": 2022,
  "price": 35000000,
  "mileage": 15000,
  "fuel": "디젤",
  "desc": "하이리무진 풀옵션"
}
```

**문의 등록**
```json
{
  "car_id": 1,
  "buyer_id": 4,
  "message": "실차 확인 가능한가요?"
}
```

## 4. 보안 계층

| 계층 | 통제 | 위협 모델 |
|---|---|---|
| Azure NSG | 22, 5000만 허용 | 1433 노출로 인한 SQL Brute force |
| SQL Server 바인딩 | `127.0.0.1` 로 listen | NSG 우회 / VNet peering 위험 |
| SA 비밀번호 | `.env` + `chmod 600` | Git 노출, 세션 환경변수 노출 |
| SSH 인증 | Key only (Password 비활성) | Brute force |
| TLS | Encrypt + TrustServerCertificate (학습용) | MITM (실무는 정식 인증서) |
| FK·CHECK 제약 | DB 레벨 무결성 | 잘못된 데이터 삽입 |
| Parameterized Query | pyodbc placeholder `?` | SQL Injection |

## 5. 운영 명령어

```bash
# 서비스 상태
sudo systemctl status carmarket
sudo systemctl status mssql-server

# 로그 실시간
sudo journalctl -u carmarket -f
sudo journalctl -u mssql-server -f

# 재시작 (.env 변경 후)
sudo systemctl restart carmarket

# DB 접속
sqlcmd -S localhost -U sa -P "$SA_PWD" -C -d CarMarket

# 통계 조회
sqlcmd -S localhost -U sa -P "$SA_PWD" -C -d CarMarket -Q \
  "SELECT Status, COUNT(*) FROM Cars GROUP BY Status"
```

## 6. 비용 모델

| 항목 | 단가 (USD) | 8시간 | 24시간 |
|---|---|---|---|
| Standard_B2s | $0.0496/hr | $0.40 | $1.19 |
| Premium SSD P10 32GB | $0.005/hr | $0.04 | $0.12 |
| Standard Public IP | $0.005/hr | $0.04 | $0.12 |
| 대역폭 (5GB 가정) | - | $0.05 | $0.05 |
| **합계** | | **약 $0.53** | **약 $1.48** |

**한 달 (월 22일 운용)**: 약 $11.66 — Azure $200 학습 크레딧 충분

## 7. 확장 시나리오

```
Phase 1 (현재) ── 단일 VM, IaaS
Phase 2 ─────── + Nginx 리버스프록시 + Let's Encrypt TLS
Phase 3 ─────── DB 분리 → Azure SQL Database (Day 5 마이그레이션)
Phase 4 ─────── App 분리 → App Service or Container Apps
Phase 5 ─────── 이미지 업로드 → Blob Storage + CDN
Phase 6 ─────── 모니터링 → Application Insights + Log Analytics
Phase 7 ─────── 자동화 → GitHub Actions CI/CD
```
