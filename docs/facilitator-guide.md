# Pet Park — Facilitator Guide

A hands-on smart contract workshop for a small group of high schoolers (built for **3 students**),
on a **real public blockchain: OP Mainnet (Optimism)**. Every student creates their own wallet,
receives under a dollar of real ETH for gas, and **writes their own Tamagotchi contract in Remix**
step by step, deploying a new version after each step. They claim SNACK tokens from a faucet
contract and spend them to feed and play with their pet and each other's pets. The **Pet Park web
app** (a static site on your VPS) renders every pet as a little Tamagotchi, live, on the projector and
on the students' laptops, and everything is public, forever, on optimistic.etherscan.io.

- **Audience:** high schoolers (15–18). No blockchain knowledge needed; some coding helps
  (they type ~170 lines, with a checkpoint file for every step).
- **Duration:** 3 h with a break. With 3 students that's a relaxed pace: extra time goes into the
  challenge cards. A 90-minute version is at the end.
- **Student setup:** a laptop with Chrome/Brave/Firefox and the MetaMask extension. Remix runs in the browser.
- **Cost:** about **US$0.10 of gas for the whole class** (measured 2026-10-21). You send each student
  0.0003 ETH (≈ US$0.75) so nobody ever runs out.

---

## 1. How it works

```
             (teacher deploys once, on OP Mainnet)         (each student deploys 4–6 versions)
  ┌─────────────────────────────────────┐            ┌────────────────────────────┐
  │ PetPark                             │◄─register──│ Tamagotchi "Bolinha" v1…v4 │
  │  • creates SNACK token (1,000,000)  │            │  owner = student wallet    │
  │  • faucet: claim() → 50 SNACK/3 min │──SNACK────►│  feed()  10 SNACK          │
  │  • registry: allPets()              │◄──SNACK────│  play()   5 SNACK          │
  └─────────────────────────────────────┘  payments  │  hug()  free · sleep() free│
              ▲          ▲                return to   │  revive() 50 SNACK         │
              │          │                the park    └────────────────────────────┘
     Pet Park app    students' own wallets (MetaMask, OP Mainnet)
```

| Contract | Who deploys | File |
|---|---|---|
| `SnackToken`: hand-written ERC-20, 0 decimals (10 SNACK is just `10`) | created by PetPark | `contracts/instructor/SnackToken.sol` |
| `PetPark`: faucet + list of every pet; recycles payments so it never runs dry | teacher, once | `contracts/instructor/PetPark.sol` |
| Starter: two interfaces + an empty contract | students paste it | `contracts/student/steps/Step0_Starter.sol` |
| Checkpoints after steps 1, 2, 3 | for anyone who falls behind | `contracts/student/steps/Step1_Egg.sol` … `Step3_PlayAndSleep.sol` |
| The complete pet (= step 4) | students, by typing | `contracts/student/Tamagotchi.sol` |
| Challenge solutions | nobody (reference) | `contracts/solutions/TamagotchiPlus.sol` |

What students type at each step is in **`docs/code-along.md`** and on the slides.

**SNACK is a play token.** It has no price and no market: it only exists to feed pets. ETH is the
real coin that pays the gas.

**Pet rules (constants in the student file):**

| Stat | Grows by | Effect at 100 | Reset by |
|---|---|---|---|
| Hunger | 2 / minute | **dies** (50 min without food) | `feed()` — 10 SNACK, anyone |
| Boredom | 3 / minute | sad face | `play()` — 5 SNACK, anyone, awake and tiredness < 80 |
| Tiredness | 2 / minute | can't play at ≥ 80 | `sleep()` — free, owner only, 2-minute nap |

**The one idea to land:** a blockchain never "ticks". The pet stores *when* it was last fed, and
`hunger()` does the maths when someone asks. Nothing runs in the background.

**In the Pet Park app** each student has one card: their newest version, with a `v1`…`v4` badge.
A step-1 pet shows as an **egg** and "hatches" when they deploy step 2.

### The Pet Park app (webapp/, on your VPS)

A static site (deploy it with `deploy/README.md`) that renders the pets with the same pixel art and
Tamagotchi device as the slides:

- **The park** (`/`): every student's newest pet in its own LCD screen, stat bars that move every
  second, "starves in 34:12" countdowns, a graveyard, leaderboards, and a live feed of every
  transaction with explorer links. `?screen=1` is the projector version: bigger, and it prints the
  site address so students can type it.
- **A pet's page** (`/#/pet/0x…`): the big Tamagotchi. Its three orange buttons are **feed**,
  **play** and **hug**; owner actions (sleep, revive) are listed beside it. Each button shows the
  function it calls and what it costs. Food, hearts, a ball and zZz animate when it happens, even
  when a friend did it from another laptop.
- **Wallet bar**: Connect (switches MetaMask to OP Mainnet by itself), ETH and SNACK balances, and a
  **Claim SNACK** button with the faucet countdown.
- **The approve step stays visible**: until the pet is allowed to spend your SNACK, the page explains
  `approve()` and offers "Allow 200 SNACK". Pressing Feed before that makes the pet say so.
- Before any transaction the app checks it for free. If it would fail, nothing is sent and **the pet
  says the contract's error** in a speech bubble ("Only my owner can do that!").
- It works with every code-along version: an egg only has a Hug button, a step-2 pet has no Play yet.

**When to use it vs Remix.** Remix is where they write and deploy, and the first time they claim,
approve and feed, do it in Remix: seeing the raw `approve(spender, amount)` form is the lesson. From
then on, the app is where they take care of pets and see everyone's. Keep it on the projector all day.

---

## 2. Why OP Mainnet

The brief: a real chain with very cheap fees, and a gas coin you can actually get. Measured on
2026-10-21 for the ~12 million gas one student uses over the workshop (4 code-along deploys of
0.5–1.6M gas, 2 challenge redeploys, ~60 interactions):

| Mainnet | Cost per student | Getting the gas coin | Notes |
|---|---|---|---|
| **OP Mainnet** (chosen) | **≈ US$0.03** | ETH, withdrawn from any exchange straight onto Optimism | 2 s blocks, Multicall3, 2 public RPCs, optimistic.etherscan.io |
| Base | ≈ US$0.18 | same (ETH) | official RPC rejects some of the app's event queries |
| XDC | ≈ US$0.006 | XDC: no bridge with liquidity found (the first choice, dropped) | otherwise excellent |
| Kaia | ≈ US$0.014 | hard to buy in Brazil | |
| Gnosis | ≈ US$0.00 today | xDAI needs a bridge | gas price swings |
| Celo | ≈ US$0.21 | CELO | public RPC limits event queries |
| Polygon | ≈ US$0.32 | POL | 2 of 3 public RPCs down during the test |
| Arbitrum | ≈ US$0.60 | ETH | official public RPC didn't answer |

OP Mainnet is a "layer 2": it runs the same software as Ethereum, bundles transactions and posts them
to Ethereum. That's why it's about a thousand times cheaper while still settling on Ethereum. On top
of gas it charges a tiny L1 data fee (about 0.0000001 ETH per pet deploy), which MetaMask adds for you.

Every script and the web app also support `NETWORK=base`, `xdc`, `gnosis`, `celo` and
`celo-sepolia` (a free testnet with an official no-login faucet).

**What "real chain" changes:**
- Students create **real wallets**. Their seed phrase protects real (if tiny) money, so the
  safety talk is not a drill.
- Pets are permanent and public. They'll still be on OP Mainnet years from now.
- There's no time travel and no reset: what's deployed is deployed.

Tested against a local fork of OP Mainnet (anvil in Optimism mode, with L1 fees): Pet Park deploy,
wallet funding, all four code-along steps, approve/feed/play/hug, a friend's `sleep()` refused, and
the web app (including its wallet flows, driven by a scripted browser).

---

## 3. Preparation

**Status for the St. Nicholas workshop (Marco, Yungwoo, Lis), as of 2026-10-21:**

| | |
|---|---|
| Bank funded on OP Mainnet (0.00397 ETH) | ✅ done |
| Real-chain rehearsal (park `0x3967DA9AfAb055b6a5268c28d0718cf51EFD3758`, set aside in `.workshop/park-optimism-rehearsal.env`) | ✅ passed |
| Pet Park app live at https://tamagotchi.chakobsa.cc | ✅ done |
| Code pushed to https://github.com/chakobsa/tamagotchi | ✅ done |
| Class park deployed: **`0x6f92eE0FC91bd93479063512384b4d8016ee917E`** (SNACK `0x13de2eF3663870c72842d8e4A488c35b8923b06e`) | ✅ done |
| `webapp/config.js` points at the class park (pushed to GitHub) | ✅ done; ⬜ upload it to the VPS |
| Demo pet "Prof" | ⬜ on the morning of the class: `./scripts/demo-pet.sh` (a pet starves 50 min after its last meal) |
| Printouts | ⬜ to do |

The day itself, step by step: **`docs/run-sheet.md`**.

### Two weeks before
- [x] Install on your laptop: [Foundry](https://getfoundry.sh) (`forge`, `cast`, `anvil`) and Node.
- [x] `./scripts/new-class.sh`: creates the class wallets (one secret mnemonic in `.workshop/`) and
      prints the **bank address** (wallet #0). The bank pays for the Pet Park deploy and the students' gas.
- [x] Fund the bank: about **US$10 of ETH** withdrawn to the bank address **on Optimism (OP Mainnet)**
      (done 2026-10-21: 0.00397 ETH). That's ~100x what a class uses; it covers future classes too.
      If you ever top it up: the withdrawal network must say Optimism / OP Mainnet, not Ethereum.
- [ ] Do the code-along yourself in Remix with your own MetaMask on OP Mainnet (section 4, from 0:40). Time it.

### A free rehearsal on your laptop (no coins spent)
`anvil` makes a private copy of OP Mainnet where every class wallet has 100 ETH:
```bash
FORK=optimism ./scripts/local-chain.sh                     # terminal 1
export NETWORK=optimism RPC_URL=http://127.0.0.1:8545      # terminal 2
./scripts/deploy-park.sh && ./scripts/rehearse.sh
./scripts/time-machine.sh 30                               # only works on the local copy
npx http-server webapp -p 8700
# http://127.0.0.1:8700/?network=optimism&rpc=http://127.0.0.1:8545&park=<PARK>
```
Afterwards, **move `.workshop/park-optimism.env` out of the way**: that park only existed on your laptop,
and `deploy-park.sh` refuses to deploy while it's there.

### The week before (on real OP Mainnet)
```bash
forge test                                   # 28 tests, all must pass
./scripts/budget.sh                          # gas price, real-money cost, bank balance
./scripts/deploy-park.sh                     # deploys the Pet Park (~US$0.005)
./scripts/rehearse.sh                        # the whole student journey with wallets #1 and #2
./scripts/webapp-config.sh                  # writes webapp/config.js with the park address
# upload webapp/ to your VPS: deploy/README.md (Caddy or nginx, ~5 minutes)
```
`rehearse.sh` uses class wallets #1 and #2, so first give them gas: `STUDENTS=2 ./scripts/fund-wallets.sh`.
Rehearse with a throwaway park, then move `.workshop/park-optimism.env` aside and deploy a fresh park
for the class, so the rehearsal's test pets don't sit in the class park.

- [x] One-click starter link (Remix opens files straight from the public repo):
      `https://remix.ethereum.org/#url=https://raw.githubusercontent.com/chakobsa/tamagotchi/main/contracts/student/steps/Step0_Starter.sol`
      For a student who falls behind, swap the file name for `Step1_Egg.sol`, `Step2_Hunger.sol`,
      `Step3_PlayAndSleep.sol`, or use `contracts/student/Tamagotchi.sol` (the complete pet).
- [ ] Print `docs/code-along.md`, the student handout and the challenge cards.

### One hour before
- [ ] `./scripts/budget.sh`: the bank has at least 0.001 ETH.
- [ ] The Pet Park app on the projector in big-screen mode (`https://tamagotchi.chakobsa.cc/?screen=1`), full
      screen (F11). The *Theme* button: light usually projects better. Write the app's address on the board.
- [ ] On the board: **remix.ethereum.org**, the **Pet Park address**, the **starter link**, and the
      app address.
- [ ] `./scripts/demo-pet.sh`: puts a fresh, fed "Prof" in the class park so the big screen isn't empty.

---

## 4. Run of show (3 hours)

| Time | Block | Slides |
|---|---|---|
| 0:00 | Hook | 1–4 |
| 0:10 | Blockchain basics + "this is a real blockchain" | 5–11 |
| 0:25 | Wallets on OP Mainnet + receiving real gas money | 12–13 |
| 0:40 | Remix, tokens and the faucet | 14–19 |
| 0:55 | **Code step 1** — the egg | 20–23 |
| 1:20 | **Code step 2** — time, hunger, food, approve | 24–31 |
| 1:45 | Break | 32 |
| 1:55 | **Code step 3** — play, sleep, friends, permissions | 33–38 |
| 2:20 | **Code step 4** — mood and revive | 39–43 |
| 2:35 | Make it yours | 44–45 |
| 2:50 | Wrap-up | 46–51 |

With 3 students you can sit next to each one in turn. Don't wait for "the whole class" at
checkpoints: wait for all three.

### 0:00 — Hook (10 min)
- Show an original Tamagotchi. Who had one? What happened when they forgot it?
- "Today you'll each **write** a pet that lives on a real blockchain. Nobody can delete it, not even
  me, and it will still be there in ten years."

### 0:10 — Blockchain basics (15 min)
- The class notebook, transactions, keys, gas, smart contracts, the "can I fix it?" quiz.
- **Real-chain slide:** OP Mainnet is a real public network built on Ethereum (a "layer 2"). Gas
  costs fractions of a cent, so we can afford to use the real thing.

### 0:25 — Wallets (15 min) · hands-on
1. Install MetaMask and **create a new wallet**. Write the 12-word secret phrase **on paper**, keep it,
   and never type it anywhere else. This one is real.
2. Network: open the Pet Park app and click **Connect wallet**: it switches MetaMask to **OP Mainnet**
   (it's in MetaMask's list of popular networks). Manually: RPC `https://mainnet.optimism.io` ·
   chain ID `10` · symbol `ETH` · explorer `https://optimistic.etherscan.io`.
3. Each student shows you their address (MetaMask → copy). You run
   `./scripts/fund-address.sh 0xTheirAddress` (0.0003 ETH each).
4. **The moment:** ETH arrives in their wallet. Their first real crypto, worth about 75 cents. Open
   the transfer on optimistic.etherscan.io together.
- Safety, out loud: this wallet is real. Anyone who asks for the secret phrase is stealing.
  Don't buy crypto because of today; today was about how it works.

### 0:40 — Remix, tokens and the faucet (15 min) · hands-on
- `SnackToken.sol` on the projector: a token is `mapping(address => uint256) balanceOf`.
- Open **remix.ethereum.org**, create `Tamagotchi.sol`, paste the **starter**, Ctrl+S.
- Deploy & Run → *Injected Provider – MetaMask*. Remix must show **chain 10** and their address.
- Contract **IPetPark** → paste the Pet Park address → **At Address** → `claim` → 50 SNACK.
- Open the claim on optimistic.etherscan.io: public, forever.

### 0:55 — Code step 1: the egg (25 min) · code-along
- Type together: state variables → events → constructor → `ageInMinutes` → `hug`.
- Deploy (`petName`, `parkAddress`) → **eggs appear on the big screen**. Hug each other's eggs.
- Now give them the Pet Park app's address: they open it, click **Connect wallet**, and find their egg.

### 1:20 — Code step 2: hunger and food (25 min) · code-along
- "The blockchain never ticks" → `lastFed`, `hunger()`, `_growsOverTime`, `require`/`whenAlive`, `feed()`/`_pay()`.
- Deploy v2 → **the egg hatches**. `feed` **fails on purpose** ("allowance too low") →
  `approve(new pet, 200)` on ISnack → `feed` works.

### 1:45 — Break (10 min)
Pets keep getting hungry (2 points a minute).

### 1:55 — Code step 3: play, sleep and friends (25 min) · code-along
- Stats, `onlyOwner`, `whenAwake`, `play`, `sleep`. Deploy v3, **approve the new address**.
- Visit each other's pets (*At Address*); `sleep()` on someone else's pet → "Only my owner can do that!".

### 2:20 — Code step 4: mood and revive (15 min) · code-along
- `mood()` (with `unicode"😄"`), `revive()`. Deploy v4: the complete pet. Approve it.

### 2:35 — Make it yours (15 min, more if you're ahead)
- Challenge cards. Deploy v5. "Your v1 egg is still on OP Mainnet, unchanged."

### 2:50 — Wrap-up (10 min)
- Recap, real-world uses, the three safety rules, awards (with 3 students: everybody wins
  something).
- **Their pets live on**: at home, with MetaMask, Remix and *At Address*, they can keep feeding them.
  Their 0.0003 ETH covers thousands more transactions.

### Live events (optional)
| Script | Effect |
|---|---|
| `./scripts/faucet-control.sh 200 0` | **Happy hour:** 200 SNACK per claim, no cooldown |
| `./scripts/faucet-control.sh 50 180` | Back to normal |
| `./scripts/fund-address.sh 0x… 0.0002` | More gas for someone (never needed in tests, but there it is) |

---

## 5. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| MetaMask shows 0 ETH | Wrong network or account | Select OP Mainnet and the right account; check the address on optimistic.etherscan.io |
| Remix shows another chain | MetaMask on a different network | Switch MetaMask to OP Mainnet, refresh Remix |
| `allowance too low — did you approve() first?` | Expected (and after **every** redeploy) | `approve(newest pet address, 200)` on ISnack |
| `not enough SNACK — visit the faucet` | Balance 0 | `claim()` on IPetPark |
| `Faucet: too soon` | 3-minute cooldown | Wait, or happy hour |
| Deploy fails at "gas estimation" | Wrong park address in the constructor | Copy the Pet Park address from the Pet Park app |
| Remix deploys ISnack/IPetPark | Wrong item in the contract dropdown | Select **Tamagotchi** |
| Transaction failed with "out of gas" | Wallet used a tight gas limit | Click again; or in MetaMask *Edit → Gas limit* +20% |
| Compile errors | See the table at the end of `code-along.md` | Or paste the checkpoint file of that step |
| A pet doesn't show in the Pet Park app | Different park address, or still confirming | Check the constructor's park address; wait a block (2 s) |
| The app says "The blockchain isn't answering" | Public RPC hiccup | Reload with `?rpc=https://optimism-rpc.publicnode.com` (or set it in `config.js`) |
| MetaMask can't reach the RPC | Same | Edit the network, use `https://optimism-rpc.publicnode.com` |

About "out of gas": the contract is written so an action never costs more later than when it was
estimated (there's a test for it), so this should not happen. It's in the table just in case.

---

## 6. No browser extensions allowed?

On school-managed laptops that block MetaMask, students can still code in Remix but can't sign.
Options: ask IT to allow MetaMask for the day; use personal laptops; or pair up. As a last resort,
Remix VM (a fake chain in the browser): no shared park, no Pet Park app, no real chain.

---

## 7. 90-minute version

| Time | Block |
|---|---|
| 0:00 | Hook + basics (15 min) |
| 0:15 | Wallets + receiving ETH (10 min) |
| 0:25 | Faucet claim + the block explorer (10 min) |
| 0:35 | **Paste** `Tamagotchi.sol` (the complete file) instead of the code-along; tour it (15 min) |
| 0:50 | Deploy, approve, feed, play, sleep (20 min) |
| 1:10 | Visit each other's pets + the `sleep()` permission fail (10 min) |
| 1:20 | Wrap-up (10 min) |

---

## 8. Notes on the design

- **Why a hand-written ERC-20?** So students can read every line.
- **Why 0 decimals?** "approve 200" means 200.
- **Why payments go back to the park:** a closed economy; the faucet never runs dry.
- **Why per-pet approvals:** the real-world pattern; a shared approval would let any pet charge any
  approved wallet.
- **Why `_growsOverTime` has no early `return`:** wallets estimate gas a moment before a transaction
  runs. An earlier version was 647 gas cheaper right after a feed, so a hug estimated in the same
  block as a feed could run out of gas a block later (this happened in testing). The fixed version
  costs the same whenever it runs, and `test_gasCostDoesNotGrowWithTime` guards it.
- **Anyone in the world can register with the park.** The web app escapes all text and only sends
  what the student signs in MetaMask, so the worst case is a stray card.
- **The web app reads all pets in one Multicall3 call** per refresh (OP Mainnet has it; on XDC,
  which doesn't, it falls back to batched `eth_call`s).
- **The class mnemonic in `.workshop/` now controls real coins** (the bank). Keep it out of git
  (`.gitignore` does that), don't share it, and don't keep more than a few dollars there.
