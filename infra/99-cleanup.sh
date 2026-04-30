#!/usr/bin/env bash
# infra/99-cleanup.sh — 비용 차단 (deallocate 또는 RG 삭제)
set -euo pipefail

RG="${RG:-rg-carmarket-lab}"
VM="${VM:-vm-sqlsrv-carmarket}"

echo "==============================================="
echo " 리소스 정리 옵션"
echo "==============================================="
echo " 1) VM Deallocate — 다음날 재개 (디스크/IP 약 \$0.08/일 유지)"
echo " 2) Resource Group 삭제 — 완전 종료 (모든 자원 삭제)"
echo " 3) 취소"
echo "==============================================="
read -p "선택 [1/2/3]: " choice

case "$choice" in
  1)
    echo "[*] VM Deallocate 중..."
    az vm deallocate --resource-group "$RG" --name "$VM" --output table
    echo "✅ Deallocate 완료. 재개 시: az vm start -g $RG -n $VM"
    ;;
  2)
    echo "[!] Resource Group 전체 삭제 — 복구 불가"
    read -p "정말 삭제하시겠습니까? RG 이름 '$RG' 입력: " confirm
    if [ "$confirm" = "$RG" ]; then
      az group delete --name "$RG" --yes --no-wait
      echo "✅ 삭제 진행 중 (백그라운드, 5~10분 소요)"
      echo "   확인: az group list --query \"[?name=='$RG']\" --output table"
    else
      echo "이름 불일치, 취소됨"
      exit 1
    fi
    ;;
  3) echo "취소"; exit 0 ;;
  *) echo "잘못된 선택"; exit 1 ;;
esac
