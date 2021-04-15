// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


abstract contract LockableERC20 is ERC20 {
    // we hope that this struct can be packed in a single 256bit word.
    struct LockInfo {
        uint128 amount;
        uint128 releaseTime;
    }
    
    
    mapping(address => LockInfo) public locked;
    
    
    function extendLock(uint128 amountToIncrease, uint128 timeToExtend) public {
        // here solidity should be able to detect overflows.
        locked[msg.sender].amount += amountToIncrease;
        require(balanceOf(msg.sender) >= locked[msg.sender].amount, "Not enough balance.");
        // another point that solidity should be able to detect overflows.
        locked[msg.sender].releaseTime += timeToExtend;
    }
    

    function _beforeTokenTransfer(address from, address, uint256 amount) internal override virtual {
        if (locked[from].amount == 0)
            return;
        if (locked[from].releaseTime < block.timestamp) {
            locked[from].amount = 0;
            locked[from].releaseTime = 0;
            return;
        }
        require(balanceOf(from) - locked[from].amount >= amount, "Can't move locked tokens.");
    }
}
    
    