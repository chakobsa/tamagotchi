#!/usr/bin/env bash
# After the workshop: sends what is left on every student card back to the class bank,
# so the coins can be reused for the next class (only works for class wallets / cards,
# not for students' own wallets).
source "$(dirname "$0")/common.sh"
check_chain
BANK="$(addr_of 0)"
GAS_PRICE="$(cast gas-price --rpc-url "$RPC_URL")"
FEE=$(( 21000 * GAS_PRICE * 3 ))            # margin for price moves (and L1 fees on L2s)
total=0
for i in $(seq 1 "$STUDENTS"); do
  a="$(addr_of "$i")"; b="$(cast balance "$a" --rpc-url "$RPC_URL")"
  (( b > FEE * 2 )) || continue
  v=$(( b - FEE ))
  if cast send "$BANK" --value "$v" --gas-limit 21000 --gas-price "$(( GAS_PRICE * 2 ))" \
       --rpc-url "$RPC_URL" --private-key "$(key_of "$i")" --async >/dev/null 2>&1; then
    total=$(( total + v )); echo "card #$i → bank $(eth "$v")"
  else
    echo "card #$i skipped"
  fi
done
echo "Swept about $(eth $total) $CURRENCY back to $BANK"
