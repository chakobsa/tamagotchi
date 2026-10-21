#!/usr/bin/env bash
# Dress rehearsal on the REAL setup: runs the student journey with cards #1 and #2, exactly as
# students will in Remix, including deploying every code-along step. Costs a little gas (about 0.005 XDC on XDC Network).
source "$(dirname "$0")/common.sh"
check_chain
source "$PARK_FILE"
cd "$ROOT"
R=(--rpc-url "$RPC_URL")
S1="$(key_of 1)"; S2="$(key_of 2)"
GAS=0
GAS_FILE="$STATE_DIR/rehearsal-deploy-gas.txt"; : > "$GAS_FILE"
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
send() { # send <key> <to> <sig> [args...]  — waits, tracks gas, prints the explorer link
  local key="$1"; shift
  local j; j="$(cast send "$@" "${R[@]}" --private-key "$key" --json)"
  local used hash; used="$(echo "$j" | sed -n 's/.*"gasUsed":"\(0x[0-9a-fA-F]*\)".*/\1/p')"; hash="$(echo "$j" | sed -n 's/.*"transactionHash":"\([^"]*\)".*/\1/p')"
  local ok; ok="$(echo "$j" | sed -n 's/.*"status":"\(0x[0-9a-f]*\)".*/\1/p')"
  [[ "$ok" == 0x1 ]] || { echo "  ✗ $2 REVERTED ${EXPLORER:+$EXPLORER/tx/$hash}"; exit 1; }
  GAS=$(( GAS + used )); echo "  ✓ $2 ${EXPLORER:+$EXPLORER/tx/$hash}"
}
deploy() { # deploy <key> <file:Contract> <name> → echoes the address
  local out; out="$(forge create "$2" "${R[@]}" --private-key "$1" --broadcast --constructor-args "$3" "$PARK" 2>&1)" || { echo "$out" >&2; exit 1; }
  local addr hash; addr="$(echo "$out" | sed -n 's/^Deployed to: //p')"; hash="$(echo "$out" | sed -n 's/^Transaction hash: //p')"
  cast receipt "$hash" gasUsed "${R[@]}" >> "$GAS_FILE"   # subshell: hand the number back via a file
  echo "$addr"
}

claim() { # claim <key> <n>: claim unless the 3-minute cooldown is still running (re-runs)
  local wait; wait="$(cast call "$PARK" 'secondsUntilClaim(address)(uint256)' "$(addr_of "$2")" "${R[@]}")"
  if [[ "$wait" == 0 ]]; then send "$1" "$PARK" 'claim()'; else echo "  (cooldown: $wait s left, using the SNACK already claimed)"; fi
}

step "1. Card #1 claims SNACK from the faucet"
claim "$S1" 1
echo "  balance: $(cast call "$SNACK" 'balanceOf(address)(uint256)' "$(addr_of 1)" "${R[@]}") SNACK"

step "2. Card #1 codes along: deploys every step"
EGG="$(deploy "$S1" contracts/student/steps/Step1_Egg.sol:Tamagotchi "Rehearsal v1")";          echo "  step 1 (egg)    $EGG"
V2="$(deploy "$S1" contracts/student/steps/Step2_Hunger.sol:Tamagotchi "Rehearsal v2")";         echo "  step 2 (hunger) $V2"
V3="$(deploy "$S1" contracts/student/steps/Step3_PlayAndSleep.sol:Tamagotchi "Rehearsal v3")";   echo "  step 3 (play)   $V3"
PET="$(deploy "$S1" contracts/student/Tamagotchi.sol:Tamagotchi "Rehearsal")";                   echo "  step 4 (final)  $PET"
echo "  park now has $(cast call "$PARK" 'petCount()(uint256)' "${R[@]}") pets"

step "3. Card #1 approves the final pet, then hugs, feeds, plays"
send "$S1" "$SNACK" 'approve(address,uint256)' "$PET" 200
for f in 'hug()' 'feed()' 'play()'; do send "$S1" "$PET" "$f"; done

step "4. Card #2 visits the friend's pet: claim, approve, feed, hug"
claim "$S2" 2
send "$S2" "$SNACK" 'approve(address,uint256)' "$PET" 200
send "$S2" "$PET" 'feed()'
send "$S2" "$PET" 'hug()'

step "5. Card #2 tries to put the friend's pet to sleep (must fail)"
if cast send "$PET" 'sleep()' "${R[@]}" --private-key "$S2" >/dev/null 2>"$STATE_DIR/err.txt"; then
  echo "UNEXPECTED: sleep() worked for a non-owner"; exit 1
else
  echo "  ✓ refused: $(grep -o 'Only my owner can do that!' "$STATE_DIR/err.txt" | head -1)"
fi

step "6. Pet status"
echo "  name   : $(cast call "$PET" 'name()(string)' "${R[@]}")"
echo "  mood   : $(cast call "$PET" 'mood()(string)' "${R[@]}")"
echo "  status : $(cast call "$PET" 'status()(uint256,uint256,uint256,uint256,bool,bool)' "${R[@]}" | tr '\n' ' ')(hunger boredom tiredness hugs alive sleeping)"
echo
for g in $(cat "$GAS_FILE"); do GAS=$(( GAS + g )); done
echo "Gas used by this rehearsal: $GAS (deploys: $(tr "\n" " " < "$GAS_FILE"))"
echo "Rehearsal OK. Final pet: $(link_addr "$PET")"
