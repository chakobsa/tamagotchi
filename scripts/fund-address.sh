#!/usr/bin/env bash
# Sends gas money to one address, e.g. a student who uses their own MetaMask wallet.
#   ./scripts/fund-address.sh 0xTheirAddress [coins, default per network]
source "$(dirname "$0")/common.sh"
check_chain
TO="${1:?usage: fund-address.sh <address> [ETH]}"
AMOUNT="${2:-$STUDENT_DEFAULT}"
tx="$(cast send "$TO" --value "$(cast to-wei "$AMOUNT")" --rpc-url "$RPC_URL" --private-key "$(key_of 0)" --json | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
echo "Sent $AMOUNT $CURRENCY to $TO"
[[ -n "$EXPLORER" ]] && echo "$EXPLORER/tx/$tx"
