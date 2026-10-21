# Run sheet — St. Nicholas · Marco, Yungwoo & Lis

One page to keep next to you. Full detail: `facilitator-guide.md`. Slide numbers match the deck.

## Before the day
1. ✅ **Class park** deployed: **`0x6f92eE0FC91bd93479063512384b4d8016ee917E`**
   (SNACK token `0x13de2eF3663870c72842d8e4A488c35b8923b06e`). ⬜ Upload `webapp/config.js` to the VPS
   (or `git pull` there): https://tamagotchi.chakobsa.cc then opens on the class park.
2. **Morning of the class:** `./scripts/demo-pet.sh` puts a fresh, fed "Prof" in the park.
3. **Starter link** (put it in a QR code or the class chat):
   `https://remix.ethereum.org/#url=https://raw.githubusercontent.com/chakobsa/tamagotchi/main/contracts/student/steps/Step0_Starter.sol`
   Checkpoints if someone falls behind: same URL with `Step1_Egg.sol`, `Step2_Hunger.sol`,
   `Step3_PlayAndSleep.sol`, or `contracts/student/Tamagotchi.sol` (complete).
4. **Print:** 3 × `code-along.md`, 3 × `student-handout.md`, `challenge-cards.md`.

## 30 minutes before
- Laptop on power, sleep off, terminal open in the repo.
- `./scripts/budget.sh`: bank has ≥ 0.001 ETH.
- Projector: https://tamagotchi.chakobsa.cc/?screen=1 full screen; deck in another tab.
- Board: `remix.ethereum.org` · `tamagotchi.chakobsa.cc` · Pet Park `0x6f92eE0FC91bd93479063512384b4d8016ee917E` · starter link.

## The workshop

**0:00 · Hook · slides 1–4**
- Do: welcome Marco, Yungwoo and Lis; Tamagotchi photo; the live park with Prof.
- Ask: "Who had one? What happened when you forgot it?"
- Say: "Today you'll each write a pet that lives on a real blockchain. Nobody can delete it, not even me."

**0:10 · Blockchain basics · slides 5–11**
- Do: shared notebook → signed lines → keys → gas → contracts → real chain.
- Ask (slide 5): "If Marco erases a line from his copy, does it work?" (No, the others still have it.)
- Ask (slide 10, vote, then reveal): "I deployed a contract with a bug. Can I fix it?" (No: deploy a new one.)

**0:25 · Wallets · slides 12–13 · hands-on**
- Students: install MetaMask, create a wallet, secret phrase on paper; tamagotchi.chakobsa.cc → Connect wallet.
- You: for each address, `./scripts/fund-address.sh 0xTheirAddress`. Celebrate the ETH arriving;
  open the transfer on optimistic.etherscan.io.
- Say (slide 13): "This wallet is real. Anyone who asks for your secret phrase is robbing you."
- ✅ All three see 0.0003 ETH.

**0:40 · Remix, tokens, faucet · slides 14–19 · hands-on**
- Students: starter link → Ctrl+S → Deploy & Run → Injected Provider (chain 10) →
  **IPetPark** → At Address (park) → **claim**.
- You: show `SnackToken.sol` ("a token is a list"); open a claim on the explorer.
- Ask: "Is `claim` orange or blue? Why?" · "What if you put your phone number in a contract?"
- ✅ All three have 50 SNACK.

**0:55 · Code step 1: the egg · slides 20–23**
- Students: type variables, constructor, events, `hug` → compile → deploy (name + park address).
- You: type along slowly; eggs pop up on the big screen. Make it loud.
- Ask: "Who becomes the owner, and why?" (`msg.sender`.)
- Then: they open their egg on tamagotchi.chakobsa.cc and hug each other's.
- ✅ Three eggs on screen.

**1:20 · Code step 2: hunger and food · slides 24–31**
- You: draw the timeline: "the blockchain never ticks".
- Students: `lastFed`, `hunger()`, `_growsOverTime` → `whenAlive` → `feed()`/`_pay()` → deploy v2 (hatches).
- Key moment: `feed` **fails on purpose**. Ask: "What does it say? Why can't the pet take your SNACK?"
  → in Remix, **ISnack** → `approve(newest pet, 200)` → `feed` works.
- Ask: "When you're not looking, is it getting hungrier?" · "Who pays when a friend feeds your pet?"
- ✅ Every pet fed once. From here they can also use the app's buttons.

**1:45 · Break · slide 32**
- Hunger keeps growing. You: `./scripts/budget.sh`.

**1:55 · Code step 3: play, sleep, friends · slides 33–38**
- Students: stats → `onlyOwner` → `whenAwake` → `play` + `sleep` → deploy v3 → **approve again** →
  play, sleep, try to play during the nap.
- Ask: "Why approve again?" (New version = new address.)
- Friends: visit each other's pets, hug, then try **Put to bed** on someone else's.
  Ask: "What did it say? Why can't anyone override that, not even me?"

**2:20 · Code step 4: mood and revive · slides 39–43**
- Students: `mood()` (emoji need `unicode"…"`), `revive()` → deploy v4 (complete) → approve.
- Ask: "What face does a hungry pet show while it's asleep?" (😴: sleep is checked first.)

**2:35 · Make it yours · slides 44–45**
- Students: a challenge card → deploy v5.
- Ask: "Where is your v1 egg now?" Open it on the explorer: still there, unchanged.

**2:50 · Wrap-up · slides 46–51**
- Do: recap, real world, the three safety rules.
- Awards, one each: "most hugged" and "oldest alive" from the park; "most creative change":
  each presents, the other two vote.
- Say: "Your pet keeps living: feed it from home at tamagotchi.chakobsa.cc."

## If something goes wrong
| They see | You do |
|---|---|
| `allowance too low` | approve the **newest** pet |
| `not enough SNACK` / `Faucet: too soon` | claim again, or happy hour: `./scripts/faucet-control.sh 200 0` (back with `50 180`) |
| Compile errors they can't fix | paste that step's checkpoint |
| Pet not in the park | check the park address in the constructor |
| Low on gas (very unlikely) | `./scripts/fund-address.sh 0xTheirAddress 0.0002` |
