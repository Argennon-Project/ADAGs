// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";


contract Ballot is Administered {
    mapping(address => uint) public votes;
    uint public totalWeight;
    uint immutable public endTime;
    uint immutable public lockTime;
    address immutable public parent = msg.sender;
    LockableToken immutable public votingToken;


    event Voted(address account, uint weight, uint total);
    event Destroyed(Ballot b);
    
    
    constructor(address payable _admin, LockableToken _votingToken, uint _endTime, uint _lockTime)
    Administered(_admin) {
        votingToken = _votingToken;
        lockTime = _lockTime;
        endTime = _endTime;
        require(block.timestamp < _endTime && _endTime < _lockTime, "ballot dates are invalid");
    }
    
    
    function changeVoteTo(uint weight) onlyBefore(endTime) public  {
        require(votingToken.locked(msg.sender).amount >= weight, "locked amount not enough");
        require(votingToken.locked(msg.sender).releaseTime >= lockTime, "lock period is too short");
        totalWeight -= votes[msg.sender];
        totalWeight += weight;
        votes[msg.sender] = weight;
        emit Voted(msg.sender, weight, totalWeight);
    }
    
    
    function destroy() public onlyBy(parent) {
        emit Destroyed(this);
        selfdestruct(admin);
    }
}
