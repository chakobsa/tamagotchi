# Code-along — build your Tamagotchi in Remix

You build the pet in 4 steps. After each step you **deploy a new version**: it's a new pet,
with a new address. The newest one is the one on the big screen.

Fell behind? Ask for the checkpoint file of the step you're on and paste it in. No shame:
real developers copy working code all the time.

| Step | You add | The pet can… | Checkpoint file |
|---|---|---|---|
| 0 | (start) | nothing yet | `steps/Step0_Starter.sol` |
| 1 | memory, birth, hugs | exist as an **egg**, get hugs | `steps/Step1_Egg.sol` |
| 2 | time, hunger, food | **hatch**, get hungry, eat, die | `steps/Step2_Hunger.sol` |
| 3 | boredom, tiredness, play, sleep | play and nap | `steps/Step3_PlayAndSleep.sol` |
| 4 | mood, revive | show its mood, come back to life | `Tamagotchi.sol` (complete) |

Comments (`// ...`) are optional: they help you, the computer ignores them.

---

## Step 0 — open the starter

1. Go to **remix.ethereum.org** → File explorer → new file **`Tamagotchi.sol`**.
2. Paste the starter file your teacher shares. It already has two *interfaces*, `ISnack` and
   `IPetPark`: small descriptions that let your code (and Remix) talk to the token and the park.
3. Press **Ctrl+S** (Cmd+S on a Mac). A green check on the compiler icon = it compiles.

---

## Step 1 — the egg 🥚

Type this **inside** `contract Tamagotchi { … }`:

```solidity
    // Who am I?
    string public name;
    address public owner;
    uint256 public birthday;

    // The world around me
    IPetPark public park;

    // My memory
    uint256 public hugs;

    event Born(string name, address indexed owner);
    event Hugged(address indexed by, uint256 totalHugs);

    constructor(string memory petName, address parkAddress) {
        name = petName;
        owner = msg.sender;
        birthday = block.timestamp;
        park = IPetPark(parkAddress);

        park.register();
        emit Born(petName, msg.sender);
    }

    function ageInMinutes() public view returns (uint256) {
        return (block.timestamp - birthday) / 1 minutes;
    }

    function hug() external {
        hugs = hugs + 1;
        emit Hugged(msg.sender, hugs);
    }
```

**Deploy:** Deploy & Run → contract **Tamagotchi** → open the arrow next to Deploy →
`petName` = a name, `parkAddress` = the Pet Park address → **transact**.
Your egg appears on the big screen. Click `hug`.

---

## Step 2 — time, hunger and food 🍙

**a) New memory and rules** — next to the other variables:

```solidity
    ISnack public snack;
    uint256 public lastFed;

    uint256 public constant FEED_COST = 10;
    uint256 public constant HUNGER_PER_MINUTE = 2;

    event Fed(address indexed by);
```

**b) In the constructor**, after `park = IPetPark(parkAddress);`:

```solidity
        snack = park.snack();
        lastFed = block.timestamp;
```

**c) New functions** — anywhere inside the contract:

```solidity
    modifier whenAlive() {
        require(isAlive(), "RIP... this pet is dead. Its owner can call revive()");
        _;
    }

    function hunger() public view returns (uint256) {
        return _growsOverTime(lastFed, HUNGER_PER_MINUTE);
    }

    function isAlive() public view returns (bool) {
        return hunger() < 100;
    }

    function feed() external whenAlive {
        _pay(FEED_COST);
        lastFed = block.timestamp;
        emit Fed(msg.sender);
    }

    function _pay(uint256 amount) internal {
        require(snack.transferFrom(msg.sender, address(park), amount), "Payment failed");
    }

    function _growsOverTime(uint256 since, uint256 perMinute) internal view returns (uint256) {
        uint256 elapsed = block.timestamp >= since ? block.timestamp - since : 0;
        uint256 points = (elapsed / 1 minutes) * perMinute;
        return points > 100 ? 100 : points;
    }
```

**d) Change one line:** `function hug() external {` → `function hug() external whenAlive {`

**Deploy a new version.** Your pet hatches on the big screen. Then:
1. `feed` → it **fails** ("allowance too low"). That's expected!
2. Contract **ISnack** → *At Address* = SNACK token → `approve(your NEW pet's address, 200)`.
3. `feed` again → hunger goes to 0.

> ⚠️ Every new version has a new address, so it needs a **new approve**.

---

## Step 3 — play and sleep ⚽😴

**a) Memory and rules:**

```solidity
    uint256 public lastPlayed;
    uint256 public lastSlept;
    uint256 public sleepingUntil;

    uint256 public constant PLAY_COST = 5;
    uint256 public constant BOREDOM_PER_MINUTE = 3;
    uint256 public constant TIREDNESS_PER_MINUTE = 2;
    uint256 public constant NAP_TIME = 2 minutes;

    event Played(address indexed by);
    event Slept(uint256 until);
```

**b) In the constructor**, under `lastFed = block.timestamp;`:

```solidity
        lastPlayed = block.timestamp;
        lastSlept = block.timestamp;
```

**c) New functions:**

```solidity
    modifier onlyOwner() {
        require(msg.sender == owner, "Only my owner can do that!");
        _;
    }

    modifier whenAwake() {
        require(!isSleeping(), "Shhh... I'm sleeping. Try again in a moment");
        _;
    }

    function boredom() public view returns (uint256) {
        return _growsOverTime(lastPlayed, BOREDOM_PER_MINUTE);
    }

    function tiredness() public view returns (uint256) {
        return _growsOverTime(lastSlept, TIREDNESS_PER_MINUTE);
    }

    function isSleeping() public view returns (bool) {
        return block.timestamp < sleepingUntil;
    }

    function play() external whenAlive whenAwake {
        require(tiredness() < 80, "Too tired to play... my owner should call sleep()");
        _pay(PLAY_COST);
        lastPlayed = block.timestamp;
        emit Played(msg.sender);
    }

    function sleep() external onlyOwner whenAlive whenAwake {
        sleepingUntil = block.timestamp + NAP_TIME;
        lastSlept = sleepingUntil;
        emit Slept(sleepingUntil);
    }
```

**Deploy a new version**, approve it, then try `play`, `sleep`, and `play` again while it naps.
Visit a friend's pet and try `sleep` on it.

---

## Step 4 — mood and revive 😄💀

**a) A rule and an event:**

```solidity
    uint256 public constant REVIVE_COST = 50;
    event Revived(address indexed by);
```

**b) New functions:**

```solidity
    function mood() public view returns (string memory) {
        if (!isAlive()) return unicode"💀";
        if (isSleeping()) return unicode"😴";

        uint256 worst = _max(hunger(), _max(boredom(), tiredness()));
        if (worst >= 80) return unicode"😫";
        if (worst >= 50) return unicode"😐";
        return unicode"😄";
    }

    function status()
        external
        view
        returns (uint256 hunger_, uint256 boredom_, uint256 tiredness_, uint256 hugs_, bool alive_, bool sleeping_)
    {
        return (hunger(), boredom(), tiredness(), hugs, isAlive(), isSleeping());
    }

    function revive() external onlyOwner {
        require(!isAlive(), "I'm alive already!");
        _pay(REVIVE_COST);
        lastFed = block.timestamp;
        lastPlayed = block.timestamp;
        lastSlept = block.timestamp;
        sleepingUntil = 0;
        emit Revived(msg.sender);
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
```

**Deploy your final pet** and approve it. It's complete! Now grab a challenge card.

---

## When the compiler complains

| Message | Usually means |
|---|---|
| `Expected ';'` | a line is missing its `;` at the end |
| `Expected '}'` / `Unexpected end of file` | a `{` without its `}` |
| `Undeclared identifier` | a typo in a name, or you used something you haven't typed yet |
| `Invalid character in string` | an emoji without `unicode` in front: `unicode"😄"` |
| `Identifier already declared` | you typed the same thing twice |
