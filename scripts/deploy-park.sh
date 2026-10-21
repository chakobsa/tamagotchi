#!/usr/bin/env bash
# Deploys the Pet Park (which creates the SNACK token) from the class bank wallet.
#   VERIFY=1 ./scripts/deploy-park.sh    also publishes the source (Blockscout on Celo Sepolia, Sourcify elsewhere),
#                                         so anyone can read it on the block explorer
source "$(dirname "$0")/common.sh"
check_chain
cd "$ROOT"

if [[ -s "$PARK_FILE" ]]; then
  echo "A Pet Park is already recorded for $NETWORK in $PARK_FILE:"; cat "$PARK_FILE"
  echo "Delete that file to deploy a new one."; exit 0
fi

ARGS=(--rpc-url "$RPC_URL" --private-key "$(key_of 0)" --broadcast)
if [[ "${VERIFY:-0}" == 1 ]]; then
  if (( ${#VERIFY_ARGS[@]} )); then ARGS+=(--verify "${VERIFY_ARGS[@]}");
  else echo "(source verification isn't set up for $NETWORK_LABEL: verify on the explorer's website if you want it)"; fi
fi
OUT="$(forge create contracts/instructor/PetPark.sol:PetPark "${ARGS[@]}" 2>&1)" || { echo "$OUT"; exit 1; }
PARK="$(echo "$OUT" | sed -n 's/^Deployed to: //p')"
[[ -n "$PARK" ]] || { echo "$OUT"; exit 1; }
SNACK="$(cast call "$PARK" 'snack()(address)' --rpc-url "$RPC_URL")"

cat > "$PARK_FILE" <<ENV
PARK=$PARK
SNACK=$SNACK
TEACHER=$(addr_of 0)
ENV

echo "Network    : $NETWORK_LABEL"
echo "Pet Park   : $PARK   $(link_addr "$PARK")"
echo "SNACK token: $SNACK   $(link_addr "$SNACK")"
echo "Saved to   : $PARK_FILE"
echo
echo "Web app    : ./scripts/webapp-config.sh, then upload webapp/ (deploy/README.md)"
