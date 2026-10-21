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

    // My memory
    uint256 public hugs;

    // Events: little announcements everyone can listen to (the dashboard does!)
    event Born(string name, address indexed owner);
    event Hugged(address indexed by, uint256 totalHugs);

    // Runs ONCE, at the moment the pet is born (deployed)
    constructor(string memory petName, address parkAddress) {
        name = petName;
        owner = msg.sender;
        birthday = block.timestamp;
        park = IPetPark(parkAddress);

        park.register(); // tell the Pet Park I exist -> I show up on the big screen
        emit Born(petName, msg.sender);
    }

    function ageInMinutes() public view returns (uint256) {
        return (block.timestamp - birthday) / 1 minutes;
    }

    /// Free, and anyone can do it 🤗
    function hug() external {
        hugs = hugs + 1;
        emit Hugged(msg.sender, hugs);
    }
}
