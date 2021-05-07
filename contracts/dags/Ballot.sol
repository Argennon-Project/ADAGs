// SPDX-License-Identifier: GPL-3.0-or-later


pragma solidity ^0.8.0;


import "./../utils/Administered.sol";


contract Ballot is Administered {
    // Solidity official docs recommends bytes32 over string.
    mapping(address => uint128) public votes;
    uint public totalWeight;
    
    // title can be used for protecting voters against phishing attacks. An attacker may be able to fool voters to
    // vote for his ballot by giving wrong information about what ballot is really about. To protect users, the
    // data of ballot should be retrieved by getBallotData() method of GovernanceSystem contract.
    bytes32 immutable public title;
    uint128 immutable public endTime;
    uint128 immutable public lockTime;
    
    address immutable private parent = msg.sender;
    LockableToken immutable private votingToken;
    
    
    constructor(address payable _admin, bytes32 _title, LockableToken _votingToken, uint128 _endTime, uint128 _lockTime)
    Administered(_admin) {
        votingToken = _votingToken;
        title = _title;
        lockTime = _lockTime;
        endTime = _endTime;
        require(block.timestamp < _endTime && _endTime < _lockTime, "Ballot dates are invalid.");
    }
    
    
    function changeVoteTo(uint128 weight) onlyBefore(endTime) public  {
        require(votingToken.locked(msg.sender).amount >= weight, "Increase your locked amount.");
        require(votingToken.locked(msg.sender).releaseTime >= lockTime, "Increase your lock period.");
        totalWeight -= votes[msg.sender];
        totalWeight += weight;
        votes[msg.sender] = weight;
    }
    
    
    function destroy() public onlyBy(parent) {
        selfdestruct(admin);
    }
}
