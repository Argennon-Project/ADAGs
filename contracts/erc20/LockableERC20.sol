// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./../utils/Tools.sol";


abstract contract LockableERC20 is ERC20 {
    // we hope that this struct can be packed in a single 256bit word.
    struct Lock {
        uint128 threshold;
        uint128 releaseTime;
    }
    struct LockedTokens {
        uint128 amount;
        uint128 releaseTime;
    }
    
    
    mapping(address => Lock) public locksData;
    
    
    function locked(address account) public view returns(LockedTokens memory) {
        return LockedTokens({
            // minimum can't be bigger than an uint128, so the cast is safe.
            amount: uint128(min(balanceOf(account), locksData[account].threshold)),
            releaseTime: locksData[account].releaseTime
        });
    }
    
    
    function extendLock(uint128 amountToIncrease, uint128 timeToExtend) public {
        // we do not check the user balance and let the user to increase his lock. this will enable use cases that an account
        // could act like a timed locked smart contract.
        
        // here solidity should be able to detect overflows.
        locksData[msg.sender].threshold += amountToIncrease;
        locksData[msg.sender].releaseTime += timeToExtend;
    }
    

    function _beforeTokenTransfer(address from, address, uint256 amount) internal override virtual {
        if (locksData[from].threshold == 0)
            return;
        if (locksData[from].releaseTime < block.timestamp) {
            locksData[from].threshold = 0;
            locksData[from].releaseTime = 0;
            return;
        }
        require(balanceOf(from) - amount >= locksData[msg.sender].threshold, "Can't move locked tokens.");
    }
}
    
    