#!/usr/bin/env bash
# BACKUP ONLY on a mainnet: prints one card per class wallet (private key included).
# The normal flow is that students create their own MetaMask wallet and you fund it with
# fund-address.sh. Cards are for a student whose laptop can't create a wallet in time.
# A printed key holds real coins on a mainnet: hand cards out only when needed, take them back.
# Writes .workshop/wallet-cards-<network>.html: print it, cut it, hand one card to each student.
source "$(dirname "$0")/common.sh"
[[ -s "$PARK_FILE" ]] || { echo "Deploy the Pet Park first (deploy-park.sh)."; exit 1; }
source "$PARK_FILE"
OUT="$STATE_DIR/wallet-cards-$NETWORK.html"

case "$NETWORK" in
  local) HOWTO="MetaMask → <b>Add network manually</b>: RPC from the board · Chain ID <code>31337</code> · ETH" ;;
  *) HOWTO="MetaMask → <b>Add network manually</b>: $NETWORK_LABEL · RPC <code>$DEFAULT_RPC</code> · Chain ID <code>$CHAIN_ID</code> · $CURRENCY · <code>$EXPLORER</code>" ;;
esac

{
cat <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>Pet Park wallet cards</title>
<style>
  @page { size: A4; margin: 10mm; }
  body { font-family: system-ui, sans-serif; margin: 0; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 6mm; }
  .card { border: 1.5px dashed #555; border-radius: 4mm; padding: 4mm 5mm; break-inside: avoid; font-size: 9.5pt; }
  .card h2 { margin: 0 0 2mm; font-size: 13pt; }
  .k { color: #555; font-size: 8pt; text-transform: uppercase; letter-spacing: .05em; margin-top: 2mm; }
  code { font-family: ui-monospace, Menlo, monospace; font-size: 8pt; word-break: break-all; }
  .warn { margin-top: 2.5mm; font-size: 7.5pt; color: #8a1c1c; }
</style></head><body><div class="grid">
HTML
for i in $(seq 1 "$STUDENTS"); do
  KEY="$(key_of "$i")"
  ADDR="$(cast wallet address --private-key "$KEY")"
  cat <<HTML
<div class="card">
  <h2>Pet Park · Wallet #$i · $NETWORK_LABEL</h2>
  <div class="k">Network</div><div>$HOWTO</div>
  <div class="k">Your private key (MetaMask → Add account → Import account)</div><code>$KEY</code>
  <div class="k">Your address</div><code>$ADDR</code>
  <div class="k">See it on the explorer</div><code>$(link_addr "$ADDR")</code>
  <div class="k">Pet Park address (your pet's constructor needs it)</div><code>$PARK</code>
  <div class="warn">Class wallet: give this card back at the end. Never type the key or seed phrase of your OWN wallet anywhere.</div>
</div>
HTML
done
echo "</div></body></html>"
} > "$OUT"
echo "Wrote $OUT ($STUDENTS cards). Open it in a browser and print."
