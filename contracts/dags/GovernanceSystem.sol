// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./Ballot.sol";
import "./TokenSale.sol";
import "./../utils/AccessControlled.sol";


uint constant MIN_LOCK_DURATION = 120 days;
uint constant MAX_LOCK_DURATION = 730 days;
uint constant MIN_MAJORITY_PERCENT = 55;
uint constant MAX_MAJORITY_PERCENT = 80;
uint constant MAX_PROPOSAL_FEE = 2e18;


// this struct is only 128 bit and we hope that it is packed in a single 256 bit storage slot
struct VotingConfig {
    uint64 proposalFee;
    uint56 lockDuration;
    uint8 majorityPercent;
}


function validate(VotingConfig memory config) pure returns (VotingConfig memory) {
    require(
        config.majorityPercent >= MIN_MAJORITY_PERCENT &&
        config.majorityPercent <= MAX_MAJORITY_PERCENT,
        "invalid majority percent"
    );
    require(
        config.lockDuration >= MIN_LOCK_DURATION &&
        config.lockDuration <= MAX_LOCK_DURATION,
        "invalid lock duration"
    );
    require(config.proposalFee <= MAX_PROPOSAL_FEE, "proposal fee is too high");
    return config;
}


contract GovernanceSystem is AccessControlled {
    // the `active` flag is added in order to make sure that a zeroed Proposal is easily detectable and does not correspond
    // to any actions. before applying a proposal `active` flag must be checked.
    struct GovernanceAction {
        bool active;
        // we define the function input as storage to prevent unnecessary struct copying
        function(bytes storage, bool) internal action;
        bytes data;
    }


    address payable public admin;
    VotingConfig public votingConfig;
    LockableMintable public governanceToken;
    TokenSale[] public tokenSales;
    mapping(Ballot => GovernanceAction) internal proposals;


    event DecodedCreateTokenSale(TokenSaleConfig tsConfig, address beneficiary);
    event DecodedApproveMinter(address minter, uint amount);
    event DecodedGovernanceChange(address newGovernanceSystem);
    event DecodedGrant(address payable recipient, uint amount, IERC20 token);
    event DecodedChangeOfSettings(address payable newAdmin, VotingConfig newVotingConfig);
    event DecodedAdminReset(Administered target, address payable admin);

    event MinterApproved(address minter, uint amount);
    event TokenSaleCreated(TokenSale newTs);
    event GovernanceSystemChanged(address newGovernanceSystem);
    event GrantGiven(address payable recipient, uint amount, IERC20 token);
    event SettingsChanged(address payable newAdmin, VotingConfig newVotingConfig);
    event AdminReset(Administered target, address payable admin);

    event PaymentReceived(address sender, uint amount);
    event BallotCreated(Ballot newBallot, uint endTime);


    // authenticates the given ballot to make sure it's our ballot.
    modifier authenticate(Ballot b) {require(proposals[b].active, "ballot not found"); _;}


    constructor(
        address payable _admin,
        LockableMintable _governanceToken,
        VotingConfig memory _votingConfig
    ) {
        admin = _admin;
        governanceToken = _governanceToken;
        votingConfig = validate(_votingConfig);
    }


    /**
     * An attacker may be able to fool voters to vote for his ballot by giving wrong information about what the
     * ballot is really about. To protect users, the data of a ballot could be decoded by this function and user
     * could verify what action the ballot will perform if it is accepted.
     */
    function DecodeBallotAction(Ballot ballot) authenticate(ballot) public {
        proposals[ballot].action(proposals[ballot].data, true);
    }


    function verifyOwnership() public {
        governanceToken.setOwner(address(this));
    }


    // any one may call this function
    function executeProposal(Ballot ballot) authenticate(ballot) onlyAfter(ballot.endTime()) public {
        // We first set the active flag of the proposal to false to make sure reentracy will not cause a proposal to be
        // applied multiple times and the authenticate(ballot) modifier will revert.
        proposals[ballot].active = false;
        if (_isMajority(ballot.totalWeight())) {
            proposals[ballot].action(proposals[ballot].data, false);
        }
        delete proposals[ballot];
        ballot.destroy();
    }


    function proposeTokenSale(TokenSaleConfig calldata config, bool governorIsBeneficiary, uint ballotEndTime)
    public payable returns (Ballot b) {
        address beneficiary;
        if (governorIsBeneficiary) {
            beneficiary = address(this);
        } else {
            beneficiary = address(governanceToken);
            require(
                governanceToken.canControl(config.fiatTokenContract),
                "governance token does not support config's fiat token"
            );
        }
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _createTokenSale, abi.encode(validate(config), beneficiary));
    }


    function proposeGrant(address payable recipient, uint amount, IERC20 token, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _grant, abi.encode(recipient, amount, token));
    }


    function proposeChangeOfSettings(address payable newAdmin, VotingConfig calldata newVotingConfig, uint ballotEndTime)
    public payable returns (Ballot b) {
        require(newAdmin != address(this), "admin can't be the contract itself");
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _changeSettings, abi.encode(newAdmin, validate(newVotingConfig)));
    }
    
    
    function proposeMintApproval(address minter, uint amount, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _approveMinter, abi.encode(minter, amount));
    }


    function proposeAdminReset(Administered target, uint ballotEndTime)
    public payable returns(Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _resetAdmin, abi.encode(target));
    }

    
    function proposeRetirement(address payable newSystem, uint ballotEndTime)
    public payable returns (Ballot b) {
        b = _newBallot(ballotEndTime);
        _saveProposal(b, _retire, abi.encode(newSystem));
    }


    receive() external virtual payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

   
    function _isMajority(uint weight) internal view returns(bool) {
        // we hope solidity will detect overflows.
        return 100 * weight > votingConfig.majorityPercent * governanceToken.totalSupply();
    }
    
    
    function _saveProposal(
        Ballot b,
        function(bytes storage, bool) internal action,
        bytes memory data
    ) internal {
        proposals[b].data = data; 
        proposals[b].action = action;
        proposals[b].active = true;
    }
    
   
    function _newBallot(uint ballotEndTime) internal returns(Ballot b) {
        require(msg.value >= votingConfig.proposalFee, "proposal fee was not paid");
        // ballot contract will do checks for times.
        uint lockTime = ballotEndTime + votingConfig.lockDuration;
        b = new Ballot(admin, governanceToken, ballotEndTime, lockTime);
        emit BallotCreated(b, ballotEndTime);
    }


    function _createTokenSale(bytes storage data, bool isForCheck) internal {
        (TokenSaleConfig memory tsConfig, address beneficiary) = abi.decode(data, (TokenSaleConfig, address));
        if (isForCheck) {
            emit DecodedCreateTokenSale(tsConfig, beneficiary);
            return;
        }
        TokenSale newTs = new TokenSale(admin, beneficiary, tsConfig);
        governanceToken.increaseMintingAllowance(address(newTs), tsConfig.totalSupply);
        tokenSales.push(newTs);
        emit TokenSaleCreated(newTs);
    }


    function _approveMinter(bytes storage data, bool isForCheck) internal {
        (address minter, uint amount) = abi.decode(data, (address, uint));
        if (isForCheck) {
            emit DecodedApproveMinter(minter, amount);
            return;
        }
        // the new amount will be added to the previous allowance amount
        governanceToken.increaseMintingAllowance(minter, amount);
        emit MinterApproved(minter, amount);
    }
    
    
    function _retire(bytes storage data, bool isForCheck) internal {
        address payable newSystem = abi.decode(data, (address));
        if (isForCheck) {
            emit DecodedGovernanceChange(newSystem);
            return;
        }
        governanceToken.setOwner(newSystem);
        // if we are the admin we should change it.
        if (governanceToken.admin() == address(this)) governanceToken.setAdmin(newSystem);
        emit GovernanceSystemChanged(newSystem);
        selfdestruct(admin);
    }


    function _grant(bytes storage data, bool isForCheck) internal{
        (address payable recipient, uint amount, IERC20 token) = abi.decode(data, (address, uint, IERC20));
        if (isForCheck) {
            emit DecodedGrant(recipient, amount, token);
            return;
        }
        // reentracy danger!
        if (address(token) == address(0)){
            recipient.transfer(amount);
        } else {
            bool success = token.transfer(recipient, amount);
            require(success, "error in token transfer");
        }
        emit GrantGiven(recipient, amount, token);
    }


    function _changeSettings(bytes storage data, bool isForCheck) internal {
        (address payable newAdmin, VotingConfig memory newVotingConfig) = abi.decode(data, (address, VotingConfig));
        if (isForCheck) {
            emit DecodedChangeOfSettings(newAdmin, newVotingConfig);
            return;
        }
        // we checked the proposal values when we were creating the proposal so we don't check them here again.
        admin = newAdmin;
        votingConfig = newVotingConfig;
        emit SettingsChanged(newAdmin, newVotingConfig);
    }

    function _resetAdmin(bytes storage data, bool isForCheck) internal {
        Administered target = abi.decode(data, (Administered));
        if (isForCheck) {
            emit DecodedAdminReset(target, admin);
            return;
        }
        target.setAdmin(admin);
        emit AdminReset(target, admin);
    }
}


