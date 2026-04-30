#!/usr/bin/env bash
# infra/02-open-ports.sh — Flask 5000 포트만 외부 노출
#
# ⚠️ 1433 포트는 절대 열지 마세요. SQL Server는 localhost 바인딩됩니다.
set -euo pipefail

RG="${RG:-rg-carmarket-lab}"
VM="${VM:-vm-sqlsrv-carmarket}"

echo "[*] NSG 5000 포트 추가 (Flask)"
az vm open-port \
  --resource-group "$RG" \
  --name "$VM" \
  --port 5000 \
  --priority 1010 \
  --output table

echo ""
echo "[*] 현재 NSG 규칙:"
az network nsg rule list \
  --resource-group "$RG" \
  --nsg-name "${VM}NSG" \
  --query "[].{Name:name, Port:destinationPortRange, Access:access, Priority:priority}" \
  --output table

echo ""
echo "✅ 완료. 브라우저에서 접속 가능:"
PUBIP=$(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)
echo "   http://${PUBIP}:5000/"
echo ""
echo "⚠️  1433 포트가 보이면 즉시 삭제하세요:"
echo "   az network nsg rule delete -g \$RG --nsg-name \${VM}NSG -n <rule-name>"
