// Pet Park web app settings. Edit this file on your server (or run ./scripts/webapp-config.sh).
// URL parameters override it: ?network=xdc&park=0x…&rpc=https://…
window.PETPARK_CONFIG = {
  network: "xdc",        // xdc | gnosis | celo | celo-sepolia | local
  park: "",              // the Pet Park address printed by ./scripts/deploy-park.sh
  rpc: "",               // optional: your own RPC URL (empty = the network's public one)
};
