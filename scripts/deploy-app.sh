#!/usr/bin/env bash
# scripts/deploy-app.sh — Flask 앱을 systemd 서비스로 등록
set -euo pipefail

APP_DIR="$HOME/sqlvm_usedcar/app"
SVC_NAME="carmarket"
SVC_FILE="/etc/systemd/system/${SVC_NAME}.service"

# 사전 체크
if [ ! -f "$APP_DIR/.env" ]; then
  echo "[!] $APP_DIR/.env 가 없습니다. .env.example을 복사 후 수정하세요:"
  echo "    cp $APP_DIR/.env.example $APP_DIR/.env"
  echo "    nano $APP_DIR/.env"
  echo "    chmod 600 $APP_DIR/.env"
  exit 1
fi

# .env 권한 확인
PERM=$(stat -c "%a" "$APP_DIR/.env")
if [ "$PERM" != "600" ]; then
  echo "[*] .env 권한을 600으로 변경..."
  chmod 600 "$APP_DIR/.env"
fi

# systemd unit 파일 생성
echo "[*] systemd unit 파일 작성..."
sudo cp "$HOME/sqlvm_usedcar/systemd/carmarket.service" "$SVC_FILE"

# WorkingDirectory와 ExecStart의 사용자 경로 치환
sudo sed -i "s|/home/azureuser|$HOME|g" "$SVC_FILE"
sudo sed -i "s|User=azureuser|User=$(whoami)|" "$SVC_FILE"

echo "[*] systemd 활성화 및 시작..."
sudo systemctl daemon-reload
sudo systemctl enable "$SVC_NAME"
sudo systemctl restart "$SVC_NAME"

sleep 2
echo ""
echo "[*] 서비스 상태:"
sudo systemctl status "$SVC_NAME" --no-pager | head -10

echo ""
echo "[*] Health Check:"
sleep 2
curl -s http://localhost:5000/health || echo "(헬스체크 실패 — 로그 확인: sudo journalctl -u $SVC_NAME -n 30)"

echo ""
echo "✅ 배포 완료"
echo "   외부 접속: http://<PUBIP>:5000/"
echo "   로그 확인: sudo journalctl -u $SVC_NAME -f"
echo ""
echo "⚠️  외부 접속 전, 로컬 PC에서 NSG 5000 포트 열기:"
echo "    bash infra/02-open-ports.sh"
