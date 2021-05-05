// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


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
    
    
    /**
     * Returns the information of the defined lock for an address. An account can't transfer any tokens as long as
     * its balance is lower than `threshold` amount. The lock will be active till `releaseTime`, and it can not 
     * be canceled by any means. A lock can only be extended.
     */
    mapping(address => Lock) public locksData;
    
    
    event LockUpdated(address account, uint128 amount, uint128 releaseTime);
    
    
    /**
     * Returns the actual amount of tokens that are locked in an account. The balance of `account` will always be
     * higher than the locked amount.
     *
     * @return a `LockedTokens` struct which its first field is the amount of locked tokens and its second field
     * is the timestamp that the tokens will be unlocked after.
     */
    function locked(address account) public view returns(LockedTokens memory) {
        return LockedTokens({
            // minimum can't be bigger than an uint128, so the cast is safe.
            amount: uint128(min(balanceOf(account), locksData[account].threshold)),
            releaseTime: locksData[account].releaseTime
        });
    }
    
    
    /**
     * Extends the defined lock on your account. This operation is irreversible.
     * 
     * @param amountToIncrease will be added to the current lock threshold, which will increase the amount
     * of locked tokens threshold.
     * @param timeToExtend will be added to the current lock's release time, which will increase the duration of
     * the lock.
     */
    function extendLock(uint128 amountToIncrease, uint128 timeToExtend) public {
        // we do not check the user balance and let the user to increase his lock threshold beyond his balance. 
        // this will enable use cases that an account could act like a timed locked smart contract.
        
        // here solidity should be able to detect overflows.
        locksData[msg.sender].threshold += amountToIncrease;
        locksData[msg.sender].releaseTime += timeToExtend;
        emit LockUpdated(msg.sender, locksData[msg.sender].threshold, locksData[msg.sender].releaseTime);
    }
    

    function _beforeTokenTransfer(address from, address, uint256 amount) internal override virtual {
        if (locksData[from].threshold == 0)
            return;
        if (locksData[from].releaseTime < block.timestamp) {
            locksData[from].threshold = 0;
            locksData[from].releaseTime = 0;
            return;
        }
        require(balanceOf(from) >= locksData[msg.sender].threshold + amount, "Not enough non-locked tokens.");
    }
}
    
    