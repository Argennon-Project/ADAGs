// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./../erc20/DistributorERC20.sol";


contract DistributorTestToken is DistributorERC20 {
    constructor(address payable admin, uint initial)
    ERC20("Distributor test", "DST")
    Administered(admin) {
        _mint(admin, initial);
    }
}