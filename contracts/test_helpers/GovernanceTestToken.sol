// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./../erc20/LockableERC20.sol";
import "./../erc20/MintableERC20.sol";


contract GovernanceTestToken is LockableERC20, MintableERC20 {
    constructor(address _owner)
    MintableERC20(_owner, "Governance test", "GRN TST", 1e25, 1e30, block.timestamp, 3 days) {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal
    override(ERC20, LockableERC20) {
        LockableERC20._beforeTokenTransfer(from, to, amount);
    }
}