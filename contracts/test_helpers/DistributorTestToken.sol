// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./../erc20/DistributorERC20.sol";


contract DistributorTestToken is DistributorERC20 {
    constructor(address payable admin)
    ERC20("Distributor test", "DST") Administered(admin) { }


    function mint(address recipient, uint amount) public {
        _mint(recipient, amount);
    }
}
