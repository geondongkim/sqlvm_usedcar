#!/usr/bin/env bash
# infra/01-create-vm.sh — Azure 리소스 그룹 + Ubuntu 22.04 VM 생성
#
# 사전 환경변수:
#   RG, LOC, VM, USER_NAME
# 또는 그냥 실행하면 기본값 사용
set -euo pipefail

RG="${RG:-rg-carmarket-lab}"
LOC="${LOC:-koreacentral}"
VM="${VM:-vm-sqlsrv-carmarket}"
USER_NAME="${USER_NAME:-azureuser}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa.pub}"

echo "==============================================="
echo " Azure VM 프로비저닝"
echo "==============================================="
echo " RG       : $RG"
echo " LOCATION : $LOC"
echo " VM       : $VM"
echo " USER     : $USER_NAME"
echo " SSH KEY  : $SSH_KEY"
echo "==============================================="
read -p "위 설정으로 진행하시겠습니까? (y/N): " ok
[[ "$ok" =~ ^[Yy]$ ]] || { echo "취소"; exit 1; }

# SSH 키 확인
if [ ! -f "$SSH_KEY" ]; then
  echo "[!] SSH 공개키가 없습니다: $SSH_KEY"
  echo "[*] 새로 생성합니다..."
  ssh-keygen -t rsa -b 4096 -N "" -f "${SSH_KEY%.pub}"
fi

# 리소스 그룹
echo "[1/3] Resource Group 생성..."
az group create --name "$RG" --location "$LOC" --output table

# VM 생성
echo "[2/3] VM 생성 중 (2~4분 소요)..."
az vm create \
  --resource-group "$RG" \
  --name "$VM" \
  --image Ubuntu2404 \
  --size Standard_B2s \
  --admin-username "$USER_NAME" \
  --ssh-key-values "$SSH_KEY" \
  --public-ip-sku Standard \
  --storage-sku Premium_LRS \
  --os-disk-size-gb 32 \
  --output table

# Public IP 출력
echo "[3/3] Public IP 조회..."
PUBIP=$(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)

echo ""
echo "==============================================="
echo " ✅ VM 생성 완료"
echo "==============================================="
echo " Public IP  : $PUBIP"
echo " SSH 접속    : ssh ${USER_NAME}@${PUBIP}"
echo ""
echo " 이후 단계:"
echo "   export PUBIP=$PUBIP"
echo "   ssh ${USER_NAME}@${PUBIP}"
echo "==============================================="
