# Make it yours — challenge cards

Edit `Tamagotchi.sol`, compile, **deploy a new version** (v5, v6…) and **approve it**: every
version has a new address. (Your old pets can't change: deployed code is permanent. They stay
on OP Mainnet, exactly as you wrote them.)

Teacher: tested solutions for every card are in `contracts/solutions/TamagotchiPlus.sol`
(search for `CHALLENGE`).

---

## 🥉 Bronze — change the rules

**B1 · New faces.** Edit `mood()` and add a super happy face when every stat is below 10.
> Hint: after `uint256 worst = ...` add `if (worst < 10) return unicode"🥰";` **before** the other `if`s.
> Emojis need the word `unicode` in front of the quotes.

**B2 · Cheap or fancy restaurant.** Change `FEED_COST` and `PLAY_COST`. Should feeding cost more than playing? Why?

**B3 · Slow down time.** Make your pet survive longer: change `HUNGER_PER_MINUTE` to `1`. How many minutes until it dies now?

**B4 · Bigger naps.** Change `NAP_TIME` to `5 minutes`. What happens to `play()` while it sleeps?

---

## 🥈 Silver — add something new

**S1 · Poop 💩.** Original Tamagotchis poop, and you have to clean up.
1. Add a state variable `uint256 public lastCleaned;` and set it in the constructor.
2. Add a view: one poop every 10 minutes since `lastCleaned`, max 5.
   ```solidity
   function poops() public view returns (uint256) {
       uint256 p = (block.timestamp - lastCleaned) / 10 minutes;
       return p > 5 ? 5 : p;
   }
   ```
3. Add `clean()`: anyone can call it, it's free, and it sets `lastCleaned = block.timestamp`.
4. In `mood()`, return `unicode"🤢"` when `poops() >= 3`.
5. In `play()`, add `require(poops() < 3, "Eww, too dirty to play. clean() first!");`

**S2 · Treats.** Add `giveTreat()` that costs 3 SNACK and only resets boredom halfway.
> Hint: you can't "subtract" boredom directly, because boredom is calculated from `lastPlayed`.
> How far *forward* should you move `lastPlayed`?

**S3 · Announce it.** Add `event Cleaned(address indexed by);` and `emit` it in `clean()`.
Find it on **optimistic.etherscan.io**: open your pet's address → the *Events* (or *Logs*) tab. (The Pet Park app knows an event called `Cleaned`
and shows it too. Call yours `Washed` instead: why does the app go quiet?)

---

## 🥇 Gold — design it yourself

**G1 · Levels.** Add `uint256 public xp;`. Every `feed()` or `play()` gives +1 xp.
Add `level()` = `xp / 5` and emit `LevelUp(level)` when the level goes up.

**G2 · Best friend.** Track `mapping(address => uint256) public friendship;`. Every time someone
other than the owner feeds or plays, +1 for them. Keep `address public bestFriend` updated
with whoever has the most points.

**G3 · Rename.** Add `rename(string calldata newName)`, owner only, 1–20 characters.
Question: renaming changes the pet… so isn't the contract changing? (What exactly is permanent: the *code* or the *data*?)

**G4 · Your own idea.** Medicine when sick? Tricks that unlock at level 3? A pet that gets
grumpy if nobody hugged it for 15 minutes? Write the rule in plain words first, then the `require`.

---

### Debug checklist
- Every line ends with `;`
- Every `{` has its `}`
- Emoji strings start with `unicode"…"`
- In the Deploy dropdown, select **Tamagotchi**, not ISnack or IPetPark
- New state variables need a starting value in the `constructor` if time matters (otherwise they start at 0, which means "January 1970")
