#!/usr/bin/env bash
# Run on the morning of the class: puts a fresh, well-fed demo pet in the class park, so the
# big screen isn't empty when students arrive. (A pet starves 50 minutes after its last meal,
# so deploying it days early would leave it in the graveyard.)
#   ./scripts/demo-pet.sh            # deploys "Prof"
#   ./scripts/demo-pet.sh Biscuit    # any name
# Uses class wallet #3 (never handed to a student) and gives it gas from the bank if needed.
source "$(dirname "$0")/common.sh"
check_chain
source "$PARK_FILE"
cd "$ROOT"
NAME="${1:-Prof}"
R=(--rpc-url "$RPC_URL"); K="$(key_of 3)"; A="$(addr_of 3)"
ok() { local j; j="$(cast send "$@" "${R[@]}" --private-key "$K" --json)" && [[ "$(echo "$j" | sed -n 's/.*"status":"\(0x[0-9a-f]*\)".*/\1/p')" == 0x1 ]]; }

if (( $(cast balance "$A" "${R[@]}") < $(cast to-wei 0.0001) )); then
  cast send "$A" --value "$(cast to-wei "$STUDENT_DEFAULT")" "${R[@]}" --private-key "$(key_of 0)" >/dev/null
  echo "Gave wallet #3 $STUDENT_DEFAULT $CURRENCY for gas"
fi
if [[ "$(cast call "$PARK" 'secondsUntilClaim(address)(uint256)' "$A" "${R[@]}")" == 0 ]]; then
  ok "$PARK" 'claim()' && echo "Claimed SNACK"
fi
PET="$(forge create contracts/student/Tamagotchi.sol:Tamagotchi "${R[@]}" --private-key "$K" --broadcast \
  --constructor-args "$NAME" "$PARK" 2>/dev/null | sed -n 's/^Deployed to: //p')"
[[ -n "$PET" ]] || { echo "Deploy failed"; exit 1; }
ok "$SNACK" 'approve(address,uint256)' "$PET" 200 && ok "$PET" 'feed()' && ok "$PET" 'hug()' || { echo "A transaction failed"; exit 1; }
echo "$NAME is in the park, fed and hugged: $(link_addr "$PET")"
echo "Its own page: https://tamagotchi.chakobsa.cc/#/pet/$PET"
