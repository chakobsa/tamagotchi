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
    // Step 1: type the code from the slides here.
}
