// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {SnackToken} from "./SnackToken.sol";

/// @title Pet Park — faucet + pet registry for the workshop
/// @notice The instructor deploys this ONCE. It:
///         1. creates the SNACK token and keeps the whole supply,
///         2. works as a faucet: anyone can claim free SNACK every few minutes,
///         3. keeps the list of every pet born in class (for the projector dashboard).
///         SNACK paid by pets comes back here, so the faucet never runs dry.
contract PetPark {
    SnackToken public immutable snack;
    address public immutable teacher;

    uint256 public dripAmount = 50; // SNACK per claim
    uint256 public cooldown = 3 minutes; // time between claims, per wallet

    mapping(address => uint256) public lastClaim;

    address[] private _pets;
    mapping(address => bool) public isPet;

    event Claimed(address indexed who, uint256 amount);
    event PetRegistered(address indexed pet);
    event FaucetChanged(uint256 dripAmount, uint256 cooldown);

    constructor() {
        teacher = msg.sender;
        snack = new SnackToken(1_000_000);
    }

    // ------------------------------------------------------------ faucet

    /// Get free SNACK. Works once every `cooldown` per wallet.
    function claim() external {
        uint256 nextClaim = lastClaim[msg.sender] + cooldown;
        require(lastClaim[msg.sender] == 0 || block.timestamp >= nextClaim, "Faucet: too soon, try again in a few minutes");
        lastClaim[msg.sender] = block.timestamp;
        require(snack.transfer(msg.sender, dripAmount), "Faucet: transfer failed");
        emit Claimed(msg.sender, dripAmount);
    }

    /// Seconds until `who` can claim again (0 = now).
    function secondsUntilClaim(address who) external view returns (uint256) {
        if (lastClaim[who] == 0) return 0;
        uint256 nextClaim = lastClaim[who] + cooldown;
        return block.timestamp >= nextClaim ? 0 : nextClaim - block.timestamp;
    }

    // ------------------------------------------------------------ registry

    /// Called by every Tamagotchi from its constructor.
    function register() external {
        require(!isPet[msg.sender], "Park: already registered");
        isPet[msg.sender] = true;
        _pets.push(msg.sender);
        emit PetRegistered(msg.sender);
    }

    function petCount() external view returns (uint256) {
        return _pets.length;
    }

    function allPets() external view returns (address[] memory) {
        return _pets;
    }

    // ------------------------------------------------------------ teacher controls

    /// Live-tune the economy during class (e.g. "happy hour": big drip, no cooldown).
    function setFaucet(uint256 newDripAmount, uint256 newCooldown) external {
        require(msg.sender == teacher, "Park: only the teacher");
        dripAmount = newDripAmount;
        cooldown = newCooldown;
        emit FaucetChanged(newDripAmount, newCooldown);
    }
}
