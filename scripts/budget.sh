#!/usr/bin/env bash
# How much gas money the workshop needs at today's prices (in coins and in US$), and what is in the bank.
source "$(dirname "$0")/common.sh"
check_chain

GAS_PRICE="$(cast gas-price --rpc-url "$RPC_URL")"
PER_STUDENT_WEI=$(( GAS_PER_STUDENT * GAS_PRICE ))
TOTAL_WEI=$(( (GAS_PER_STUDENT * STUDENTS + GAS_TEACHER) * GAS_PRICE ))

echo "Network        : $NETWORK_LABEL (chain $CHAIN_ID) via $RPC_URL"
echo "Gas price now  : $GAS_PRICE wei ($(cast from-wei "$GAS_PRICE" gwei) gwei)"
echo "Per student    : $(eth $PER_STUDENT_WEI) $CURRENCY  (~$GAS_PER_STUDENT gas$([[ $NETWORK == optimism || $NETWORK == base ]] && echo ", plus a tiny L1 data fee"))"
echo "Whole class    : $(eth $TOTAL_WEI) $CURRENCY  for $STUDENTS students + teacher, at today's price"
if [[ -n "${PRICE_ID:-}" ]]; then
  PRICE="$(curl -s --max-time 10 "https://api.coingecko.com/api/v3/simple/price?ids=$PRICE_ID&vs_currencies=usd" | sed -n 's/.*"usd":\([0-9.e-]*\).*/\1/p')"
  if [[ -n "$PRICE" ]]; then
    COST="$(awk -v w="$(eth $TOTAL_WEI)" -v p="$PRICE" 'BEGIN{printf "%.4f", w*p}')"
    echo "In real money  : 1 $CURRENCY = US\$ $PRICE → the whole class ≈ US\$ $COST"
  fi
fi
if [[ -s "$MNEMONIC_FILE" ]]; then
  echo "Bank balance   : $(eth "$(cast balance "$(addr_of 0)" --rpc-url "$RPC_URL")") $CURRENCY"
fi
echo
echo "Getting $CURRENCY: $(funding_hint)"
echo "Each student gets STUDENT_ETH (default $STUDENT_DEFAULT $CURRENCY, ~10x what they use) from fund-wallets.sh"
echo "or fund-address.sh. Re-run them during class if anyone runs low."
