#!/usr/bin/env bash
# Writes webapp/config.js for the current NETWORK, using the Pet Park you deployed with deploy-park.sh.
# Then upload the webapp/ folder to your server (see deploy/README.md).
source "$(dirname "$0")/common.sh"
[[ -s "$PARK_FILE" ]] || { echo "No Pet Park recorded for $NETWORK. Run ./scripts/deploy-park.sh first."; exit 1; }
source "$PARK_FILE"
PUBLIC_RPC="${PUBLIC_RPC:-}"      # optional: an RPC URL for the browsers (default: the network's public one)
cat > "$ROOT/webapp/config.js" <<JS
// Pet Park web app settings — written by scripts/webapp-config.sh on $(date -u +%Y-%m-%dT%H:%MZ).
// URL parameters override it: ?network=…&park=…&rpc=…
window.PETPARK_CONFIG = {
  network: "$NETWORK",
  park: "$PARK",
  rpc: "$PUBLIC_RPC",
};
JS
echo "Wrote webapp/config.js → network=$NETWORK park=$PARK"
echo "Upload it:  rsync -av --delete webapp/ you@your-vps:/var/www/petpark/"
