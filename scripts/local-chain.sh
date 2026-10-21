#!/usr/bin/env bash
# A private chain on this laptop for rehearsing without spending real coins.
#   ./scripts/local-chain.sh                 empty local chain; then use NETWORK=local with the other scripts
#   FORK=optimism ./scripts/local-chain.sh   a free copy of OP Mainnet (same chain id, real contracts):
#                                            then use NETWORK=optimism RPC_URL=http://127.0.0.1:8545
#   (FORK=base, xdc, gnosis, celo and celo-sepolia work the same way)
# Every class wallet gets 100 coins. A block every 2 s.
NETWORK=local source "$(dirname "$0")/common.sh"
mnemonic >/dev/null
ARGS=(--host 127.0.0.1 --port "$PORT" --mnemonic "$(mnemonic)" --accounts "$((STUDENTS + 1))" --balance 100 --block-time 2)
case "${FORK:-}" in
  "")           ARGS+=(--chain-id 31337 --state "$STATE_DIR/local-chain-state.json") ;;
  optimism|base|xdc|gnosis|celo|celo-sepolia) ARGS+=(--fork-url "${FORK_URL:-$(NETWORK=$FORK bash -c 'source "$0"; echo "$DEFAULT_RPC"' "$(dirname "$0")/common.sh")}")
    [[ "$FORK" == optimism || "$FORK" == base ]] && ARGS+=(--network optimism) ;;   # OP-stack tx types + L1 fees
  *) echo "FORK must be optimism, base, xdc, gnosis, celo or celo-sepolia"; exit 1 ;;
esac
exec anvil "${ARGS[@]}"
