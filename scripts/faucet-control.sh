#!/usr/bin/env bash
# Live-tune the SNACK faucet.   ./scripts/faucet-control.sh <dripAmount> <cooldownSeconds>
#   normal:       ./scripts/faucet-control.sh 50 180
#   happy hour:   ./scripts/faucet-control.sh 200 0
source "$(dirname "$0")/common.sh"
check_chain
source "$PARK_FILE"
cast send "$PARK" 'setFaucet(uint256,uint256)' "${1:?drip}" "${2:?cooldown}" \
  --rpc-url "$RPC_URL" --private-key "$(key_of 0)" >/dev/null
echo "Faucet now gives $(cast call "$PARK" 'dripAmount()(uint256)' --rpc-url "$RPC_URL") SNACK every $(cast call "$PARK" 'cooldown()(uint256)' --rpc-url "$RPC_URL") s"
