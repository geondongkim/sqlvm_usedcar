#!/usr/bin/env bash
# scripts/install-tools.sh — mssql-tools18 + ODBC Driver 18 + Python 가상환경
#
# 대상: Ubuntu 24.04 LTS
# 참조: https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools
set -euo pipefail

echo "==============================================="
echo " mssql-tools18 + ODBC Driver 18 + Python"
echo "==============================================="

# OS 검증
OS_REL=$(lsb_release -rs 2>/dev/null || echo "")
if [ "$OS_REL" != "24.04" ]; then
  echo "[!] Ubuntu 24.04 전용. 현재: $OS_REL"
  exit 1
fi

# prod.list 24.04 등록 (mssql-tools, ODBC, msodbcsql18 포함)
echo "[1/4] prod.list 저장소 등록 (Ubuntu 24.04용)..."
sudo rm -f /etc/apt/sources.list.d/mssql-release.list

curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list | \
  sudo tee /etc/apt/sources.list.d/mssql-release.list > /dev/null

sudo apt update

# mssql-tools18 + unixodbc + ODBC Driver 18
echo "[2/4] mssql-tools18 + unixodbc-dev + msodbcsql18 설치..."
sudo ACCEPT_EULA=Y apt install -y mssql-tools18 unixodbc-dev msodbcsql18

# PATH 추가
if ! grep -q "mssql-tools18/bin" "$HOME/.bashrc"; then
  echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> "$HOME/.bashrc"
fi
export PATH="$PATH:/opt/mssql-tools18/bin"

# Python (Ubuntu 24.04는 Python 3.12 기본 탑재)
echo "[3/4] Python 3 + venv 설치..."
sudo apt install -y python3 python3-pip python3-venv python3-dev

# 작업 디렉토리 + 가상환경
echo "[4/4] Python 가상환경 + 패키지..."
APP_DIR="$HOME/sqlvm_usedcar/app"
if [ ! -d "$APP_DIR" ]; then
  echo "[!] $APP_DIR 가 없습니다. git clone 또는 cd 위치를 확인하세요."
  exit 1
fi

cd "$APP_DIR"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# 검증
echo ""
echo "[*] sqlcmd 버전:"
sqlcmd -? 2>&1 | head -3 || true

echo ""
echo "[*] pyodbc 드라이버 목록:"
python3 -c "import pyodbc; print(pyodbc.drivers())"

echo ""
echo "✅ 도구 설치 완료"
echo "   다음 단계:"
echo "   1) cd ~/sqlvm_usedcar"
echo "   2) read -s -p 'SA Password: ' SA_PWD && export SA_PWD"
echo "   3) sqlcmd -S localhost -U sa -P \"\$SA_PWD\" -C -i sql/schema.sql"
echo "   4) sqlcmd -S localhost -U sa -P \"\$SA_PWD\" -C -i sql/seed.sql"
