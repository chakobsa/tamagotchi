#!/usr/bin/env bash
# Shared settings for every workshop script. Override any of them with env vars:
#   NETWORK=optimism (default, OP Mainnet) | base | xdc | gnosis | celo | celo-sepolia (testnet) | local
#   RPC_URL=...      use another RPC endpoint instead of the public one
#   STUDENTS=3       how many student wallets to manage (fund-wallets.sh, wallet-cards.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="$ROOT/.workshop"            # class mnemonic + deployed addresses (git-ignored)
mkdir -p "$STATE_DIR"

NETWORK="${NETWORK:-optimism}"
STUDENTS="${STUDENTS:-3}"
PORT="${PORT:-8545}"

# Networks. The workshop runs on a REAL chain with very cheap gas, measured 2026-10-21 for the ~12M gas
# a student uses: OP Mainnet ~ US$0.03 per student (ETH, withdrawable from any exchange straight onto
# Optimism: no bridge), Base ~ US$0.18, XDC ~ US$0.006 (but hard to buy), Gnosis ~ 0, Celo ~ US$0.21.
# OP-stack chains (optimism, base) also charge a tiny L1 data fee: ~0.0000001 ETH per pet deploy.
# celo-sepolia is a free testnet (official faucet, no login) for rehearsals.
# STUDENT_DEFAULT = coins sent to each student (~10x what they use). PRICE_ID = CoinGecko id, for budget.sh.
case "$NETWORK" in
  optimism)
    DEFAULT_RPC="https://mainnet.optimism.io"       # also: https://optimism-rpc.publicnode.com
    CHAIN_ID=10; NETWORK_LABEL="OP Mainnet"; CURRENCY="ETH"
    EXPLORER="https://optimistic.etherscan.io"; FAUCET=""; STUDENT_DEFAULT=0.0003; PRICE_ID=ethereum
    VERIFY_ARGS=(--verifier sourcify) ;;
  base)
    DEFAULT_RPC="https://base-rpc.publicnode.com"   # also: https://mainnet.base.org (rejects some log queries)
    CHAIN_ID=8453; NETWORK_LABEL="Base"; CURRENCY="ETH"
    EXPLORER="https://basescan.org"; FAUCET=""; STUDENT_DEFAULT=0.0005; PRICE_ID=ethereum
    VERIFY_ARGS=(--verifier sourcify) ;;
  xdc)
    DEFAULT_RPC="https://rpc.xdcrpc.com"            # also: https://erpc.xinfin.network, https://rpc1.xinfin.network
    CHAIN_ID=50; NETWORK_LABEL="XDC Network"; CURRENCY="XDC"
    EXPLORER="https://xdcscan.com"; FAUCET=""; STUDENT_DEFAULT=2; PRICE_ID=xdce-crowd-sale
    VERIFY_ARGS=() ;;
  gnosis)
    DEFAULT_RPC="https://rpc.gnosischain.com"
    CHAIN_ID=100; NETWORK_LABEL="Gnosis"; CURRENCY="xDAI"
    EXPLORER="https://gnosis.blockscout.com"; FAUCET=""; STUDENT_DEFAULT=0.05; PRICE_ID=xdai
    VERIFY_ARGS=(--verifier blockscout --verifier-url "https://gnosis.blockscout.com/api/") ;;
  celo)
    DEFAULT_RPC="https://forno.celo.org"
    CHAIN_ID=42220; NETWORK_LABEL="Celo"; CURRENCY="CELO"
    EXPLORER="https://celo.blockscout.com"; FAUCET=""; STUDENT_DEFAULT=10; PRICE_ID=celo
    VERIFY_ARGS=(--verifier blockscout --verifier-url "https://celo.blockscout.com/api/") ;;
  celo-sepolia)
    DEFAULT_RPC="https://forno.celo-sepolia.celo-testnet.org"
    CHAIN_ID=11142220; NETWORK_LABEL="Celo Sepolia (testnet)"; CURRENCY="CELO"
    EXPLORER="https://celo-sepolia.blockscout.com"; FAUCET="https://faucet.celo.org/celo-sepolia"; STUDENT_DEFAULT=2; PRICE_ID=
    VERIFY_ARGS=(--verifier blockscout --verifier-url "$EXPLORER/api/") ;;
  local)
    DEFAULT_RPC="http://127.0.0.1:$PORT"
    CHAIN_ID=31337; NETWORK_LABEL="Local"; CURRENCY="ETH"
    EXPLORER=""; FAUCET=""; STUDENT_DEFAULT=1; PRICE_ID=; VERIFY_ARGS=() ;;
  *) echo "Unknown NETWORK=$NETWORK (use optimism, base, xdc, gnosis, celo, celo-sepolia or local)"; exit 1 ;;
esac
RPC_URL="${RPC_URL:-$DEFAULT_RPC}"

MNEMONIC_FILE="$STATE_DIR/mnemonic.txt"
PARK_FILE="$STATE_DIR/park-$NETWORK.env"

# Gas used by one student over the whole workshop, measured on the class contracts:
# ~6 pet deploys (4 code-along steps + 2 challenge redeploys) + ~60 transactions.
GAS_PER_STUDENT=12000000
GAS_TEACHER=4000000                    # park deploy + rehearsal + funding transactions

mnemonic() {
  [[ -s "$MNEMONIC_FILE" ]] || { echo "No class wallets yet: run ./scripts/new-class.sh first." >&2; exit 1; }
  cat "$MNEMONIC_FILE"
}
# Wallet 0 = the class "bank" (teacher), wallets 1..STUDENTS = the cards
key_of() { cast wallet private-key --mnemonic "$(mnemonic)" --mnemonic-index "$1"; }
addr_of() { cast wallet address --private-key "$(key_of "$1")"; }

# Refuses to continue when RPC_URL points at a different chain than NETWORK says.
check_chain() {
  local got
  got="$(cast chain-id --rpc-url "$RPC_URL" 2>/dev/null)" || { echo "Cannot reach $RPC_URL"; exit 1; }
  # a local fork keeps the forked chain's id; that's fine for rehearsals
  if [[ "$got" != "$CHAIN_ID" && ! ( "$NETWORK" == "local" ) ]]; then
    echo "RPC $RPC_URL is chain $got, but NETWORK=$NETWORK expects $CHAIN_ID. Stopping."; exit 1
  fi
}

eth() { cast from-wei "$1"; }          # wei -> whole coins (ETH, XRP…), for printing
# How to get the gas coin into the bank, for messages
funding_hint() {
  if [[ -n "$FAUCET" ]]; then echo "free from the faucet: $FAUCET";
  else echo "buy a little $CURRENCY on an exchange (for ETH: about US\$ 10, the usual minimum withdrawal) and withdraw it to this address on $NETWORK_LABEL (chain $CHAIN_ID), not on another chain"; fi
}
link_addr() { [[ -n "$EXPLORER" ]] && echo "$EXPLORER/address/$1" || echo "$1"; }
