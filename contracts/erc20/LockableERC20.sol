// SPDX-License-Identifier: AGPL-3.0-only


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
    
    
    event LockUpdated(address account, uint128 threshold, uint128 releaseTime);


    /**
     * Returns the actual amount of tokens that are locked in an account till the release time. The balance of
     * `account` will always be higher than the locked amount. The release time may have been expired and should
     * always be checked.
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
     * @param threshold is the maximum amount of locked tokens. When the balance of your account is higher than this
     * threshold, the extra token may be transferred.
     * @param releaseTime is the lock's release time. After this time the lock will be deactivated.
     */
    function setLock(uint128 threshold, uint128 releaseTime) public {
        // we do not check the user balance and let the user increase his lock threshold beyond his balance.
        // this will enable use cases that an account could act like a timed locked smart contract.
        _updateLock(msg.sender);
        require(
            threshold >= locksData[msg.sender].threshold &&
            releaseTime >= locksData[msg.sender].releaseTime,
            "locks can only be extended"
        );
        locksData[msg.sender].threshold = threshold;
        locksData[msg.sender].releaseTime = releaseTime;
        emit LockUpdated(msg.sender, locksData[msg.sender].threshold, locksData[msg.sender].releaseTime);
    }


    function _beforeTokenTransfer(address from, address, uint256 amount) internal override virtual {
        // This if is added to save gas. we update the lock after this check to reduce transfer's gas consumption.
        if (locksData[from].threshold == 0)
            return;
        _updateLock(from);
        require(balanceOf(from) >= locksData[msg.sender].threshold + amount, "not enough non-locked tokens");
    }


    function _updateLock(address account) internal {
        if (locksData[account].releaseTime < block.timestamp) {
            locksData[account].threshold = 0;
            locksData[account].releaseTime = 0;
        }
    }
}
