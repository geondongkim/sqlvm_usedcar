# 🚗 SQL VM Used Car — 중고차 커뮤니티 MVP

**Azure Linux VM + SQL Server 2025 + Python Flask** 핸즈온 실습

> Azure Database Engineer Bootcamp · Day 3 보충 실습 · OpenScale

[![Azure](https://img.shields.io/badge/Azure-Linux%20VM-0078D4?logo=microsoftazure)](https://azure.microsoft.com)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu)](https://releases.ubuntu.com/24.04/)
[![SQL Server](https://img.shields.io/badge/SQL%20Server-2025-CC2927?logo=microsoftsqlserver)](https://www.microsoft.com/sql-server)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://www.python.org)
[![Flask](https://img.shields.io/badge/Flask-3.x-000000?logo=flask)](https://flask.palletsprojects.com)

---

## 📖 개요

Azure CLI로 Ubuntu **24.04 LTS** VM을 생성하고, **SQL Server 2025 Developer Edition**을 설치하여 중고차 매물 관리 웹서비스(Users·Cars·Inquiries 3-table)를 구축합니다. 외부 접근은 Flask 5000 포트만 열고 SQL 1433은 차단하는 이중 보안 구성입니다.

> **버전 선택 근거**: SQL Server 2022는 Ubuntu 22.04까지만 공식 지원합니다. 24.04는 SQL Server 2025 CU1부터 GA. 본 실습은 최신 LTS OS + 최신 SQL Server 조합을 사용합니다.

**🎯 학습 목표**
- Azure CLI로 Linux VM 생성·운영 자동화
- SQL Server 2025를 Linux에 설치·구성·바인딩
- Microsoft ODBC Driver 18 + pyodbc 표준 연결 패턴
- Flask REST API + Bootstrap 5 단일 페이지 통합
- NSG + SQL Server localhost 바인딩 이중 보안
- systemd 서비스화로 운영 가능한 배포

**⏱️ 소요 시간**: 약 6시간
**💰 일일 비용**: 약 $0.5/인 (B2s + Premium SSD + Standard Public IP)

---

## 🏗️ 아키텍처

```
┌──────────────────────────────────────────────────────────┐
│  Local PC (브라우저)                                      │
│  http://<PUBIP>:5000  ─────┐                             │
└────────────────────────────┼─────────────────────────────┘
                             │
                  ┌──────────┴──────────────┐ NSG: 22, 5000 only
                  │   Standard Public IP    │ (1433 차단)
                  └──────────┬──────────────┘
                             │
┌────────────────────────────┴─────────────────────────────┐
│  Azure VM  (Ubuntu 24.04 LTS, Standard_B2s)             │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ Flask App (gunicorn :5000)  ────► pyodbc ──────┐   │ │
│  │ systemd: carmarket.service                     │   │ │
│  └────────────────────────────────────────────────┼───┘ │
│                                                   │     │
│  ┌────────────────────────────────────────────────▼───┐ │
│  │ SQL Server 2025 Developer (bind 127.0.0.1:1433)   │ │
│  │ DB: CarMarket  (Users / Cars / Inquiries)         │ │
│  └────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

---

## 📂 디렉토리 구조

```
sqlvm_usedcar/
├── README.md                  ← 이 문서
├── LICENSE                    ← MIT
├── .gitignore
├── docs/
│   ├── CarMarket_HandsOn_Workbook.docx     ← 36페이지 실습 워크북
│   ├── Linux_SQLServer_Reference_Guide.docx ← 50페이지 레퍼런스 가이드 (신규)
│   └── architecture.md
├── infra/                     ← Azure 인프라 스크립트
│   ├── 01-create-vm.sh
│   ├── 02-open-ports.sh
│   └── 99-cleanup.sh
├── scripts/                   ← VM 내부 설치 자동화
│   ├── install-mssql.sh
│   ├── install-tools.sh
│   └── deploy-app.sh
├── sql/                       ← DB 스키마·시드
│   ├── schema.sql
│   └── seed.sql
├── app/                       ← Flask 애플리케이션
│   ├── app.py
│   ├── requirements.txt
│   ├── templates/index.html
│   └── .env.example
└── systemd/
    └── carmarket.service
```

---

## 📚 학습 자료

이 repo는 두 종류의 학습 문서를 제공합니다:

### 1. 실습 워크북 (`docs/CarMarket_HandsOn_Workbook.docx` · 36p)
**"무엇을 어떤 순서로 할지"** — Step 1~10의 절차적 가이드. 명령어를 그대로 따라 입력하며 6시간 안에 MVP를 완성.

### 2. 레퍼런스 가이드 (`docs/Linux_SQLServer_Reference_Guide.docx` · 50p)
**"왜 그렇게 동작하는지"** — 학습 동반서. 5부 구성:
- **Part I**: Linux 명령어 기초 (SSH, 파일, 권한, 프로세스, 네트워크, 패키지, systemd, 모니터링, 텍스트 처리)
- **Part II**: SQL Server on Linux 운영 (설치·설정·sqlcmd·ODBC·백업·보안)
- **Part III**: 핵심 용어 사전 (50+ 용어 정의·예시)
- **Part IV**: 자주 발생하는 오류와 진단 (16건의 트러블슈팅)
- **Part V**: 한 페이지 치트시트 (빠른 참조용)

### 추천 사용법
- 실습 시작 전 → 워크북 읽기
- 실습 중 모르는 용어·명령 → 레퍼런스 Part III 검색
- 오류 발생 → 레퍼런스 Part IV 트러블슈팅
- 일상 운영 → Part V 치트시트 인쇄

---

## 🚀 빠른 시작 (Quick Start)

### 사전 요구 사항
- Azure 구독 (학습 쿠폰 가능)
- Azure CLI 2.50+
- SSH 키 페어 (`~/.ssh/id_rsa.pub`)
- 로컬: bash/zsh (Linux/Mac) 또는 WSL/Git Bash (Windows)

### Step 1: 환경변수 설정 (로컬)

```bash
export RG=rg-carmarket-lab
export LOC=koreacentral
export VM=vm-sqlsrv-carmarket
export USER_NAME=azureuser
```

### Step 2: VM 생성 (로컬)

```bash
bash infra/01-create-vm.sh
```

생성 완료 후 출력되는 Public IP를 `$PUBIP`로 저장:

```bash
export PUBIP=$(az vm show -d -g $RG -n $VM --query publicIps -o tsv)
echo $PUBIP
```

### Step 3: VM 내부 설치 (SSH 후)

```bash
ssh azureuser@$PUBIP

# VM 내부에서:
git clone https://github.com/jhjwlee/sqlvm_usedcar.git
cd sqlvm_usedcar

# SQL Server 설치 (대화형 — SA 비밀번호 입력 필요)
bash scripts/install-mssql.sh

# 도구 + Python 환경 설치
bash scripts/install-tools.sh
```

### Step 4: DB 스키마 + 시드

```bash
# VM 내부에서, SA 비밀번호 입력
read -s -p "SA Password: " SA_PWD && export SA_PWD
sqlcmd -S localhost -U sa -P "$SA_PWD" -C -i sql/schema.sql
sqlcmd -S localhost -U sa -P "$SA_PWD" -C -i sql/seed.sql
```

### Step 5: Flask 앱 배포

```bash
cd ~/sqlvm_usedcar/app
cp .env.example .env
nano .env   # SA_PASSWORD 값 입력
chmod 600 .env

bash ../scripts/deploy-app.sh
```

### Step 6: NSG 5000 포트 열기 (로컬)

```bash
bash infra/02-open-ports.sh
```

### Step 7: 브라우저 접속

```
http://<PUBIP>:5000/
```

---

## 🧪 검증

### Health Check

```bash
curl http://$PUBIP:5000/health
# 기대값: {"db":"connected","status":"ok"}
```

### API 테스트

```bash
# 차량 목록
curl http://$PUBIP:5000/api/cars

# 브랜드 필터
curl "http://$PUBIP:5000/api/cars?brand=BMW"

# 매물 등록
curl -X POST http://$PUBIP:5000/api/cars \
  -H "Content-Type: application/json" \
  -d '{"seller_id":1,"brand":"기아","model":"카니발","year":2022,"price":35000000,"mileage":15000}'
```

### 보안 검증 (외부에서 SQL 차단 확인)

로컬 PC에서 실행 — `Connection refused` 또는 `timeout`이 정답:

```bash
nc -zv $PUBIP 1433
# 또는 (Windows PowerShell)
Test-NetConnection -ComputerName $env:PUBIP -Port 1433
```

---

## 💰 비용

| 항목 | 1일 (8h) 기준 | 1주 |
|---|---|---|
| VM (Standard_B2s) | $0.40 | $2.80 |
| Premium SSD P10 (32GB) | $0.04 | $0.28 |
| Standard Public IP | $0.04 | $0.28 |
| **합계** | **약 $0.49** | **약 $3.36** |

⚠️ **퇴근 시 반드시 `bash infra/99-cleanup.sh` 실행** (deallocate 또는 RG 삭제)

---

## 🛡️ 보안 모범사례

1. **1433 외부 노출 절대 금지** — Brute force 1순위 표적
2. **SQL Server 자체 127.0.0.1 바인딩** + NSG 차단 (이중 안전)
3. **`.env` 파일** + `chmod 600` 으로 SA 비밀번호 분리
4. **SSH key 인증만** 허용, 비밀번호 인증 금지
5. **HTTPS 적용**은 도메인 확보 후 Let's Encrypt + Nginx (실무 가이드 별도)

---

## 📚 부트캠프 다른 일자와의 연계

| 일자 | 활용 방안 |
|---|---|
| Day 4 (SQL PaaS) | 본 실습 SQL VM을 Azure SQL DB로 이관 비교 |
| Day 5 (마이그레이션) | DMA·DMS로 본 DB를 Azure SQL DB로 이관 실습 |
| Day 7 (튜닝) | `IX_Cars_Brand` 인덱스 효과를 Query Store로 측정 |
| Day 8 (거버넌스) | Microsoft Purview로 PII 컬럼(Email, Phone) 분류 |
| Day 9 (백업·DR) | 본 DB 백업 자동화 + 복구 시나리오 |

---

## 🐛 트러블슈팅

전체 36페이지 워크북 `docs/CarMarket_HandsOn_Workbook.docx` 부록 A 참조.

자주 발생하는 8가지 문제와 해결책:
1. SSH 접속 거부 → NSG 22 포트 / SSH 키 경로
2. mssql-server 시작 실패 → `journalctl -u mssql-server -n 50`
3. sqlcmd SSL 인증서 오류 → `-C` 옵션 추가
4. pyodbc 설치 실패 → `unixodbc-dev` 누락
5. `/health`가 db error → `.env` 비밀번호 / 서비스 상태
6. 외부 5000 접속 실패 → NSG 규칙 / Flask 0.0.0.0 바인딩
7. systemd 서비스 시작 실패 → `journalctl -u carmarket -n 80`
8. JSON POST 400 → Content-Type 헤더 누락

---

## 📄 라이선스

[MIT License](LICENSE) — 자유롭게 사용·수정·재배포 가능. 단 보증 없음.

---

## 👥 기획·제작

5개 팀 토의로 설계된 실습 자료:
- 🏗️ 인프라팀 — VM/OS/SQL Server 설치
- 💻 웹개발팀 — 백엔드/프론트엔드
- 🌐 네트워크팀 — NSG/외부 접근/보안
- 🧪 테스트팀 — 단계별 검증/통합 테스트
- 📝 교재팀 — 워크북 구조/실습 흐름

**OpenScale** · Azure Database Engineer Bootcamp 2026
