#!/usr/bin/env bash
# REHEARSAL ONLY (local chain or fork): jumps time forward so you can watch pets get hungry.
# A real chain runs on real time; nobody can skip it.   ./scripts/time-machine.sh <minutes>
source "$(dirname "$0")/common.sh"
cast rpc anvil_nodeInfo --rpc-url "$RPC_URL" >/dev/null 2>&1 || { echo "Not a local anvil chain: time travel only works in rehearsals."; exit 1; }
cast rpc evm_increaseTime "$(( ${1:?minutes} * 60 ))" --rpc-url "$RPC_URL" >/dev/null
cast rpc evm_mine --rpc-url "$RPC_URL" >/dev/null
echo "Time jumped $1 minutes."
