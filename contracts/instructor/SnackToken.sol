// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SNACK — the money of the Pet Park
/// @notice A complete ERC-20 token written by hand, so you can read every line.
///         A token is just a contract that keeps a list of "who owns how much".
///         It has 0 decimals: 10 SNACK is stored as the number 10.
contract SnackToken {
    string public constant name = "Snack";
    string public constant symbol = "SNACK";
    uint8 public constant decimals = 0;

    uint256 public totalSupply;

    // The heart of every token: address => balance
    mapping(address => uint256) public balanceOf;

    // owner => spender => how much the spender may take from the owner
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// All SNACK is created once, at birth, and handed to whoever deploys the token.
    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    /// Send your own SNACK to someone.
    function transfer(address to, uint256 value) external returns (bool) {
        _move(msg.sender, to, value);
        return true;
    }

    /// Allow `spender` (for example your pet) to take up to `value` SNACK from you.
    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /// Used by a spender you approved: move SNACK from `from` to `to`.
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= value, "SNACK: allowance too low - did you approve() first?");
        allowance[from][msg.sender] = allowed - value;
        _move(from, to, value);
        return true;
    }

    function _move(address from, address to, uint256 value) internal {
        require(to != address(0), "SNACK: cannot send to the zero address");
        require(balanceOf[from] >= value, "SNACK: not enough SNACK - visit the faucet");
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }
}
