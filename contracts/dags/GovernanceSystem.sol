// SPDX-License-Identifier: 


pragma solidity ^0.8.0;


import "./Ballot.sol";
import "./CrowdFunding.sol";


uint64 constant MIN_LOCK_DURATION = 210 days;
uint constant MAX_STAKE_DIVISOR = 1e5;

contract GovernanceSystem is Administered {
    // the `active` flag is added in order to make sure that a zeroed Proposal is easily detectable and does not correspond
    // to any actions. before applying a proposal `active` flag must be checked.
    struct GovernanceAction { 
        bool active;
        // we define the function input as storage to prevent unnecessary struct copying
        function(bytes storage) internal action;
        bytes data;
    }
     
    
    LockableMintable public governanceToken;
    CrowdFunding[] public crowdFundings;
    
    mapping(Ballot => GovernanceAction) internal proposals;
    uint64 internal lockDuration = MIN_LOCK_DURATION;
    uint internal stakeDivisor = MAX_STAKE_DIVISOR;
    
    
    // it authenticates the given ballot to make sure it's our ballot.
    modifier authenticate(Ballot b) {require(proposals[b].active, "Ballot not found."); _;} 
   
    
    constructor(address payable _admin, LockableMintable _governanceToken)
    Administered (_admin) {
        governanceToken = _governanceToken;
    }
    
    
    function getBallotData(Ballot b) authenticate(b) public view returns (bytes memory) {
        return proposals[b].data;
    }


    function proposeCrowdFund(CrowdFundingConfig calldata config, uint128 ballotEndTime) public returns (Ballot b) {
        b = _newBallot(ballotEndTime, "Crowdfunding");
        require(governanceToken.canControl(config.fiatTokenContract), "fiat token not supported.");
        _saveProposal(b, _createCF, abi.encode(validate(config)));
    }
    
    
    function proposeMintApproval(address minter, uint amount, uint128 ballotEndTime) public returns (Ballot b) {
        b = _newBallot(ballotEndTime, "Minting Approval");
        _saveProposal(b, _approveMinter, abi.encode(minter, amount));
    }
    
    
    function proposeRetirement(GovernanceSystem newSystem, uint128 ballotEndTime) onlyBy(admin) public returns (Ballot b) {
        b = _newBallot(ballotEndTime, "DANGER: Changing Governor");
        _saveProposal(b, _retire, abi.encode(address(newSystem)));
    }
    
   
    // any one may call this function
    function executeProposal(Ballot ballot) authenticate(ballot) onlyAfter(ballot.endTime()) public {
        if (_isMajority(ballot.totalWeight())) {
            proposals[ballot].action(proposals[ballot].data);
        }
        // when we are here, either we have an applied ballot or an ended ballot which failed to reach majority.
        // So we should delete the ballot.
        proposals[ballot].active = false;
        delete proposals[ballot];
        ballot.destroy();
    }
    
   
    function _isMajority(uint weight) internal view returns(bool) {
        // we hope solidity will detect overflows.
        return 3 * weight > 2 * governanceToken.totalSupply(); 
    }
    
    
    function _saveProposal(
        Ballot b,
        function(bytes storage) internal action,
        bytes memory data
    ) internal virtual {
        proposals[b].data = data; 
        proposals[b].action = action;
        proposals[b].active = true;
    }
    
   
    function _newBallot(uint128 ballotEndTime, bytes32 title) internal returns(Ballot) {
        require(
            ballotEndTime < block.timestamp + lockDuration / 2,
            "Ballot end time is too far."
        );
        uint128 lockTime = ballotEndTime + lockDuration; 
        require(
            governanceToken.locked(msg.sender).releaseTime >= lockTime,
            "Lock time is not enough."
        );
        require(
            governanceToken.locked(msg.sender).amount >= governanceToken.totalSupply() / stakeDivisor,
            "Locked amount is not enough."
        );
        // ballot contract will do other checks for times.
        return new Ballot(admin, title, governanceToken, ballotEndTime,  lockTime);
    }
    
    
    function _createCF(bytes storage data) internal {
        (CrowdFundingConfig memory cfConfig) = abi.decode(data, (CrowdFundingConfig));
        CrowdFunding result = new CrowdFunding(admin, address(governanceToken), cfConfig);
        governanceToken.approveMinting(address(result), cfConfig.totalSupply);
        crowdFundings.push(result);
    }
    
    
    function _approveMinter(bytes storage data) internal {
        (address minter, uint amount) = abi.decode(data, (address, uint));
        // first we have to set the allowance to zero to make sure the call will not fail in case that minter has
        // a non-zero allowance.
        governanceToken.approveMinting(minter, 0);
        governanceToken.approveMinting(minter, amount);
    }
    
    
    function _retire(bytes storage data) internal {
        address newSystem = abi.decode(data, (address));
        governanceToken.setOwner(newSystem);
        selfdestruct(admin);
    }
}

