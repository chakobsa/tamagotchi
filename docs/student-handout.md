# 🥚 Pet Park — write a pet that lives on a real blockchain

**Write these down from the board:**

| | |
|---|---|
| Remix | `remix.ethereum.org` |
| Starter file | open the link your teacher shares (it opens Remix with the file) |
| Pet Park address | `0x6f92eE0FC91bd93479063512384b4d8016ee917E` |
| SNACK token address | `0x13de2eF3663870c72842d8e4A488c35b8923b06e` |
| **Pet Park app** | **tamagotchi.chakobsa.cc** |
| **My wallet address** | `0x________________________________________` |
| **My newest pet's address** | `0x________________________________________` |
| A friend's pet | `0x________________________________________` |

---

## Step 1 — Your wallet on OP Mainnet
1. Install **MetaMask** and create a new wallet.
   Write the 12-word secret phrase **on paper** and keep it safe. This wallet is real.
2. Open the **Pet Park app** and click **Connect wallet**: it switches MetaMask to **OP Mainnet**
   for you. (By hand, if needed:)

   | | |
   |---|---|
   | Network name | OP Mainnet |
   | RPC URL | `https://mainnet.optimism.io` |
   | Chain ID | `10` |
   | Currency symbol | `ETH` |
   | Block explorer | `https://optimistic.etherscan.io` |

3. Copy your address and show it to your teacher. You'll receive **0.0003 ETH** for gas: real
   coins, worth about 75 cents, enough for thousands of transactions.
4. ✅ You see 0.0003 ETH. Look up your address on **optimistic.etherscan.io**.

> 🔐 **Real life rule:** never type your secret phrase or private key anywhere, never send a photo
> of it, never tell it to anyone. Anyone who asks for it is trying to rob you.

## Step 2 — Remix + SNACK from the faucet
1. In Remix, create `Tamagotchi.sol`, paste the **starter file**, press **Ctrl+S**.
2. **Deploy & Run** tab → Environment: **Injected Provider – MetaMask**. Check it says chain **10**.
3. Contract dropdown: **IPetPark** → paste the *Pet Park address* → **At Address**.
4. Open it under *Deployed Contracts* → **claim** → confirm in MetaMask.
5. ✅ You have **50 SNACK** (a play token, for pets only). Find the transaction on **optimistic.etherscan.io**.

## Step 3 — Code your pet (follow the slides or the code-along sheet)
| Step | You add | Then |
|---|---|---|
| 1 | memory, birth, `hug` | deploy → an **egg** on the big screen |
| 2 | time, `hunger`, `feed` | deploy → it **hatches**. `approve` it, then `feed` |
| 3 | `play`, `sleep` | deploy → `approve`, play, nap |
| 4 | `mood`, `revive` | deploy → `approve`. Your pet is complete! |

**To deploy:** contract **Tamagotchi** → arrow next to **Deploy** → `petName` + `parkAddress` → **transact**.

**To approve** (needed before `feed` or `play`, and again **after every new version**):
contract **ISnack** → *At Address* = SNACK token → **approve**(`spender` = your newest pet, `amount` = `200`).

🟠 **Orange buttons** = transactions: they change the blockchain, cost a tiny bit of ETH, need MetaMask.
🔵 **Blue buttons** = reading: free and instant.

⏰ **Hunger grows 2 points per minute. At 100 your pet dies** (50 minutes without food).

## The Pet Park app
Open the **Pet Park app** address from the board and click **Connect wallet**. You'll see every pet
in class, live. Click your pet to open its Tamagotchi: the three orange buttons are **Feed**,
**Play** and **Hug**. It also has **Claim SNACK** at the top, and **Allow 200 SNACK** (that's
`approve()`) when your newest pet needs it. Every action links to the block explorer.

## Step 4 — Visit a friend
1. Contract **Tamagotchi** → your friend's pet address in **At Address** → click it.
2. Hug it. To feed it, **approve your friend's pet too**.
3. Try `sleep` on your friend's pet. What happens? Why?

## When something goes wrong
| Message | What to do |
|---|---|
| `allowance too low - did you approve() first?` | approve your **newest** pet |
| `not enough SNACK - visit the faucet` | claim |
| `Faucet: too soon` | wait 3 minutes, or ask a friend to feed your pet |
| `insufficient funds for gas` | tell your teacher |
| `RIP... this pet is dead` | owner: `revive` (50 SNACK) |
| `Too tired to play` | owner: `sleep` |
| `Only my owner can do that!` | that's not your pet 😉 |
| Compiler errors | missing `;` or `}`, a typo, or `unicode` missing before an emoji |

**Take it home:** your pet lives on OP Mainnet forever. With MetaMask, Remix and your pet's address
(*At Address*), you can keep feeding it from anywhere.

---

### Words you learned today
**Blockchain**: a shared notebook nobody can erase. **Mainnet**: the real network, with real coins
(today: OP Mainnet, which runs on top of Ethereum). **Wallet**: holds your secret key, which signs your transactions.
**Transaction**: a signed change to the blockchain. **Gas**: the fee for a transaction, paid in ETH.
**Smart contract**: a program on the blockchain whose code can't change after it's deployed.
**Token**: a contract keeping a list of who owns how much. **Faucet**: gives out free tokens.
**Allowance (approve)**: permission for someone else to spend up to N of your tokens.
**Block explorer**: a website (like optimistic.etherscan.io) that shows everything on the blockchain.
