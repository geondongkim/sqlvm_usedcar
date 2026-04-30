#!/usr/bin/env bash
# scripts/install-mssql.sh — SQL Server 2025 Developer Edition 설치 + localhost 바인딩
#
# 대상: Ubuntu 24.04 LTS (Noble)
# SQL Server 2025 (17.x) — Ubuntu 24.04 공식 지원 (CU1 GA, 2026-01)
# 참조: https://learn.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu
#
# VM(Ubuntu 24.04) 내부에서 실행
set -euo pipefail

echo "==============================================="
echo " SQL Server 2025 Developer 설치 (Ubuntu 24.04)"
echo "==============================================="

# OS 검증
OS_REL=$(lsb_release -rs 2>/dev/null || echo "")
OS_CODE=$(lsb_release -cs 2>/dev/null || echo "")
if [ "$OS_REL" != "24.04" ]; then
  echo "[!] 이 스크립트는 Ubuntu 24.04 (noble) 전용입니다."
  echo "    현재 OS: $OS_REL ($OS_CODE)"
  echo "    Ubuntu 22.04 사용자는 SQL Server 2022 + 22.04 저장소를 사용하세요."
  exit 1
fi
echo "[*] OS 확인: Ubuntu $OS_REL ($OS_CODE) ✓"

# Swap 추가 — 메모리 6GB 미만일 때만
RAM_GB=$(free -g | awk 'NR==2{print $2}')
if [ "$RAM_GB" -lt 6 ] && ! swapon --show | grep -q swapfile; then
  echo "[*] RAM ${RAM_GB}GB → 2GB swap 추가 (B2s 등 저메모리 VM 보호)"
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  if ! grep -q "/swapfile" /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
  fi
elif [ "$RAM_GB" -ge 6 ]; then
  echo "[*] RAM ${RAM_GB}GB → swap 생략 (충분한 메모리)"
fi

# 시스템 업데이트
echo "[*] 패키지 업데이트..."
sudo apt update
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release

# 기존 잘못된 설정 정리 (재실행 안전성)
sudo rm -f /etc/apt/sources.list.d/mssql-server-2022.list
sudo rm -f /etc/apt/sources.list.d/mssql-server-preview.list
sudo rm -f /etc/apt/trusted.gpg.d/microsoft.asc

# Microsoft GPG 키 등록 (Ubuntu 24.04 권장 방식)
echo "[*] Microsoft GPG 키 등록..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | \
  sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

# SQL Server 2025 저장소 등록 (Ubuntu 24.04 공식)
echo "[*] SQL Server 2025 저장소 등록..."
curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list | \
  sudo tee /etc/apt/sources.list.d/mssql-server-2025.list > /dev/null

sudo apt update

# 설치
echo "[*] mssql-server 패키지 설치 (2~3분 소요)..."
sudo apt install -y mssql-server

echo ""
echo "==============================================="
echo " 다음 단계: SA 비밀번호 설정 (대화형)"
echo "==============================================="
echo " - Edition: 2 (Developer)"
echo " - License: Yes"
echo " - SA Password: 8자 이상, 대/소/숫자/특수문자 중 3종 이상"
echo "   예) CarMarket@2026"
echo "==============================================="
read -p "Enter를 눌러 setup 시작..."

sudo /opt/mssql/bin/mssql-conf setup

# localhost 바인딩 (보안 핵심)
echo ""
echo "[*] SQL Server를 127.0.0.1 전용으로 바인딩..."
sudo /opt/mssql/bin/mssql-conf set network.ipaddress 127.0.0.1
sudo systemctl restart mssql-server

# 검증
echo ""
echo "[*] 서비스 상태 확인..."
sudo systemctl status mssql-server --no-pager | head -8

echo ""
echo "[*] 바인딩 확인 (127.0.0.1:1433 만 보여야 정상):"
sudo ss -tlnp | grep 1433 || echo "ss 명령어가 없습니다. sudo apt install iproute2"

echo ""
echo "✅ SQL Server 2025 설치 완료"
echo "   다음 단계: bash scripts/install-tools.sh"
