#!/usr/bin/env bash
# Step 1 of the setup. Creates the class wallets (one secret mnemonic, kept in .workshop/)
# and tells you how much gas money (XDC by default) the class bank needs.
source "$(dirname "$0")/common.sh"

if [[ -s "$MNEMONIC_FILE" ]]; then
  echo "Class wallets already exist ($MNEMONIC_FILE). Move .workshop/ aside to start a new class."
else
  cast wallet new-mnemonic --words 12 | awk 'f{print; exit} /^Phrase:/{sub(/^Phrase:[[:space:]]*/,""); if (length) {print; exit}; f=1}' > "$MNEMONIC_FILE"
  [[ $(wc -w < "$MNEMONIC_FILE") -eq 12 ]] || { echo "could not create a mnemonic"; rm -f "$MNEMONIC_FILE"; exit 1; }
  chmod 600 "$MNEMONIC_FILE"
  echo "Created the class wallets: $MNEMONIC_FILE"
fi

echo
echo "Class bank (wallet #0): $(addr_of 0)"
echo "  Fill it with $CURRENCY: $(funding_hint)"
echo
"$(dirname "$0")/budget.sh"
