#!/usr/bin/env bash
# Tops up every student card (wallets 1..STUDENTS) to STUDENT_ETH from the class bank.
# Safe to re-run any time: wallets that already have enough are skipped.
#   STUDENT_ETH=2 ./scripts/fund-wallets.sh
source "$(dirname "$0")/common.sh"
check_chain
STUDENT_ETH="${STUDENT_ETH:-$STUDENT_DEFAULT}"
TARGET="$(cast to-wei "$STUDENT_ETH")"
BANK_KEY="$(key_of 0)"; BANK="$(addr_of 0)"
NONCE="$(cast nonce "$BANK" --rpc-url "$RPC_URL" --block pending)"

need=0; todo=()
for i in $(seq 1 "$STUDENTS"); do
  a="$(addr_of "$i")"; b="$(cast balance "$a" --rpc-url "$RPC_URL")"
  if (( b < TARGET )); then todo+=("$i:$a:$(( TARGET - b ))"); need=$(( need + TARGET - b )); fi
done
bank_bal="$(cast balance "$BANK" --rpc-url "$RPC_URL")"
echo "${#todo[@]} of $STUDENTS cards need a top-up to $STUDENT_ETH $CURRENCY: $(eth $need) in total. Bank has $(eth "$bank_bal")."
(( ${#todo[@]} == 0 )) && exit 0
(( bank_bal > need )) || { echo "Not enough in the bank ($BANK). Add more $NETWORK_LABEL ETH first."; exit 1; }

last=""
for t in "${todo[@]}"; do
  IFS=: read -r i a amount <<<"$t"
  last="$(cast send "$a" --value "$amount" --nonce "$NONCE" --async \
          --rpc-url "$RPC_URL" --private-key "$BANK_KEY")"
  echo "card #$i  +$(eth "$amount")  $last"
  NONCE=$(( NONCE + 1 ))
done
echo "Waiting for the last transfer to confirm…"
cast receipt "$last" --rpc-url "$RPC_URL" --confirmations 1 >/dev/null
echo "Done. Spot-check a card: $(link_addr "$(addr_of 1)")"
