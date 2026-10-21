#!/usr/bin/env bash
# A private chain on this laptop for rehearsing without spending real coins.
#   ./scripts/local-chain.sh                 empty local chain; then use NETWORK=local with the other scripts
#   FORK=xdc ./scripts/local-chain.sh        a free copy of XDC mainnet (same chain id, real contracts):
#                                            then use NETWORK=xdc RPC_URL=http://127.0.0.1:8545
#   (FORK=gnosis, FORK=celo and FORK=celo-sepolia work the same way)
# Every class wallet gets 100 coins. A block every 2 s.
NETWORK=local source "$(dirname "$0")/common.sh"
mnemonic >/dev/null
ARGS=(--host 127.0.0.1 --port "$PORT" --mnemonic "$(mnemonic)" --accounts "$((STUDENTS + 1))" --balance 100 --block-time 2)
case "${FORK:-}" in
  "")           ARGS+=(--chain-id 31337 --state "$STATE_DIR/local-chain-state.json") ;;
  xdc|gnosis|celo|celo-sepolia) ARGS+=(--fork-url "${FORK_URL:-$(NETWORK=$FORK bash -c 'source "$0"; echo "$DEFAULT_RPC"' "$(dirname "$0")/common.sh")}") ;;
  *) echo "FORK must be xdc, gnosis, celo or celo-sepolia"; exit 1 ;;
esac
exec anvil "${ARGS[@]}"
