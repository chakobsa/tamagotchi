# Pet Park — a Tamagotchi smart contract workshop

A small group of high schoolers (built for 3) write their own Tamagotchi smart contract in Remix,
step by step, and deploy it to **OP Mainnet (Optimism)**: a real public blockchain where the whole
class costs about US$0.10 of gas. They claim SNACK (a play token) from a faucet contract and spend
it to feed and play with their pets. The **Pet Park web app** (on your VPS) renders every pet live
as a little Tamagotchi, lets students care for them with MetaMask, and runs on the projector; and
everything is public on optimistic.etherscan.io.

```
contracts/
  instructor/SnackToken.sol          hand-written ERC-20, 0 decimals
  instructor/PetPark.sol             creates SNACK, faucet (claim) + pet registry
  student/steps/Step0_Starter.sol    what students paste first: interfaces + empty contract
  student/steps/Step1_Egg.sol        checkpoints for students who fall behind
  student/steps/Step2_Hunger.sol
  student/steps/Step3_PlayAndSleep.sol
  student/Tamagotchi.sol             the complete pet (= end of step 4)
  solutions/TamagotchiPlus.sol       challenge-card solutions (teacher copy)
test/                                forge tests (28): every step, the park, solutions, gas stability
scripts/                             all take NETWORK=optimism (default) | base | xdc | gnosis | celo | celo-sepolia | local
  new-class.sh                       creates the class wallets, prints the bank address + budget
  budget.sh                          gas price → coins and US$ needed; bank balance
  deploy-park.sh                     deploys PetPark from the bank
  fund-address.sh <addr> [coins]     sends gas money to a student's own wallet (default 0.0003 ETH)
  fund-wallets.sh                    tops up the class wallets (cards) to STUDENT_ETH
  wallet-cards.sh                    backup: printable cards for class wallets
  rehearse.sh                        the whole student journey (all 4 steps) with class wallets #1 and #2
  faucet-control.sh <n> <s>          live-tune the SNACK faucet (happy hour)
  sweep.sh                           leftover coins from the class wallets back to the bank
  local-chain.sh                     free rehearsal: local chain, or FORK=optimism for a copy of OP Mainnet
  time-machine.sh <min>              skip time (local rehearsal only)
webapp/                              the Pet Park web app: static site for your VPS (config.js = settings)
deploy/                              nginx / Caddy configs + how to deploy the web app
  (scripts/webapp-config.sh writes webapp/config.js from the deployed park)
docs/
  facilitator-guide.md               why OP Mainnet, run of show, setup checklists, troubleshooting
  code-along.md                      exactly what students type at each step
  student-handout.md                 one page per student
  challenge-cards.md                 bronze / silver / gold "make it yours" tasks
```

## Quick start

```bash
forge test
./scripts/new-class.sh                 # → withdraw ~US$10 of ETH to the bank address it prints, on Optimism
./scripts/budget.sh
./scripts/deploy-park.sh
STUDENTS=2 ./scripts/fund-wallets.sh && ./scripts/rehearse.sh
./scripts/webapp-config.sh             # then upload webapp/ to your VPS: deploy/README.md
npx http-server webapp -p 8700         # or try it locally first → http://127.0.0.1:8700/
# in class, for each student's own MetaMask address:
./scripts/fund-address.sh 0xStudentAddress
```

`.workshop/` holds the class mnemonic (it controls the bank's real ETH) and deployed addresses.
It's git-ignored: keep it that way.

Read `docs/facilitator-guide.md` before the workshop.

## Slides

The 51-slide deck (with speaker notes and timings) is a claude.ai Slides artifact, not part of this
repository. Export it as PDF or PPTX from its Share → Export menu and add it to a `slides/` folder
if you want it here. The facilitator guide's run of show lists the slide numbers for each block.

## Licenses

`lib/forge-std` (Apache-2.0 OR MIT) and `webapp/vendor/ethers.umd.min.js` (MIT, see
`webapp/vendor/ethers-LICENSE.md`) are vendored third-party code.
