// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./../erc20/LockableERC20.sol";


contract LockableTestToken is LockableERC20 {
    constructor(address owner, uint initial) ERC20("lockable test", "TST") {
        _mint(owner, initial);
    }
}