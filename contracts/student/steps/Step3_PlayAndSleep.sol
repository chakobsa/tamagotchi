// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ============================================================================
//  🥚  TAMAGOTCHI — a virtual pet that lives on the blockchain
//
//  Deploy it with:   petName   = "Bolinha"      (any name you like)
//                    parkAddress = 0x...          (your teacher gives you this)
// ============================================================================

// ---- Tools to talk to the SNACK token and the Pet Park ---------------------
// (In Remix you can also use these with "At Address" to claim and approve.)

interface ISnack {
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IPetPark {
    function snack() external view returns (ISnack);
    function claim() external;
    function secondsUntilClaim(address who) external view returns (uint256);
    function register() external;
}

// ---- The pet ---------------------------------------------------------------

contract Tamagotchi {
    // Who am I?
    string public name;
    address public owner;
    uint256 public birthday;

    // The world around me
    IPetPark public park;
    ISnack public snack;

    // My memory: WHEN did things last happen?
    // (The blockchain never "ticks". We save the time, and do the math when asked.)
    uint256 public lastFed;
    uint256 public lastPlayed;
    uint256 public lastSlept;
    uint256 public sleepingUntil;
    uint256 public hugs;

    // Rules of the game — change these to make the pet yours!
    uint256 public constant FEED_COST = 10; // SNACK
    uint256 public constant PLAY_COST = 5; // SNACK
    uint256 public constant HUNGER_PER_MINUTE = 2; // 100 = dead -> 50 minutes without food
    uint256 public constant BOREDOM_PER_MINUTE = 3;
    uint256 public constant TIREDNESS_PER_MINUTE = 2;
    uint256 public constant NAP_TIME = 2 minutes;

    // Events: little announcements everyone can listen to (the dashboard does!)
    event Born(string name, address indexed owner);
    event Fed(address indexed by);
    event Played(address indexed by);
    event Slept(uint256 until);
    event Hugged(address indexed by, uint256 totalHugs);

    // Runs ONCE, at the moment the pet is born (deployed)
    constructor(string memory petName, address parkAddress) {
        name = petName;
        owner = msg.sender;
        birthday = block.timestamp;
        park = IPetPark(parkAddress);
        snack = park.snack();

        lastFed = block.timestamp;
        lastPlayed = block.timestamp;
        lastSlept = block.timestamp;

        park.register(); // tell the Pet Park I exist -> I show up on the big screen
        emit Born(petName, msg.sender);
    }

    // ---- Rules that protect the pet (modifiers) ----------------------------

    modifier onlyOwner() {
        require(msg.sender == owner, "Only my owner can do that!");
        _;
    }

    modifier whenAlive() {
        require(isAlive(), "RIP... this pet is dead. Its owner can call revive()");
        _;
    }

    modifier whenAwake() {
        require(!isSleeping(), "Shhh... I'm sleeping. Try again in a moment");
        _;
    }

    // ---- How am I feeling? (0 = great, 100 = terrible) ---------------------
    // "view" functions only READ: they are free and need no transaction.

    function hunger() public view returns (uint256) {
        return _growsOverTime(lastFed, HUNGER_PER_MINUTE);
    }

    function boredom() public view returns (uint256) {
        return _growsOverTime(lastPlayed, BOREDOM_PER_MINUTE);
    }

    function tiredness() public view returns (uint256) {
        return _growsOverTime(lastSlept, TIREDNESS_PER_MINUTE);
    }

    function isAlive() public view returns (bool) {
        return hunger() < 100;
    }

    function isSleeping() public view returns (bool) {
        return block.timestamp < sleepingUntil;
    }

    function ageInMinutes() public view returns (uint256) {
        return (block.timestamp - birthday) / 1 minutes;
    }

    // ---- Things you can do with me (these change the blockchain = transactions)

    /// Free, and anyone can do it 🤗
    function hug() external whenAlive {
        hugs = hugs + 1;
        emit Hugged(msg.sender, hugs);
    }

    /// Costs FEED_COST SNACK. Anyone can feed me (remember to approve() first!)
    function feed() external whenAlive {
        _pay(FEED_COST);
        lastFed = block.timestamp;
        emit Fed(msg.sender);
    }

    /// Costs PLAY_COST SNACK. I need to be awake and not too tired.
    function play() external whenAlive whenAwake {
        require(tiredness() < 80, "Too tired to play... my owner should call sleep()");
        _pay(PLAY_COST);
        lastPlayed = block.timestamp;
        emit Played(msg.sender);
    }

    /// Free, but only my owner can put me to bed.
    function sleep() external onlyOwner whenAlive whenAwake {
        sleepingUntil = block.timestamp + NAP_TIME;
        lastSlept = sleepingUntil; // fully rested when I wake up
        emit Slept(sleepingUntil);
    }

    // ---- Internal helpers (nobody outside can call these) ------------------

    /// Takes SNACK from whoever is calling and sends it back to the Pet Park.
    function _pay(uint256 amount) internal {
        require(snack.transferFrom(msg.sender, address(park), amount), "Payment failed");
    }

    /// 0 at `since`, then +perMinute every minute, never above 100.
    function _growsOverTime(uint256 since, uint256 perMinute) internal view returns (uint256) {
        // time since `since` (0 if `since` is still in the future, e.g. during a nap)
        uint256 elapsed = block.timestamp >= since ? block.timestamp - since : 0;
        uint256 points = (elapsed / 1 minutes) * perMinute;
        return points > 100 ? 100 : points;
    }
}
