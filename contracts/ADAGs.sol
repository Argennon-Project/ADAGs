// SPDX-License-Identifier: AGPL-3.0-only


pragma solidity ^0.8.0;


import "./dags/GovernanceSystem.sol";


uint56 constant INITIAL_LOCK_DURATION = 180 days;
uint64 constant INITIAL_PROPOSAL_FEE = 1e14;
uint8 constant INITIAL_MAJORITY_PERCENT = 66;


contract ADAGs is GovernanceSystem {
    bool private initialCrowdfundingCreated;


    constructor(address payable _admin, LockableMintable _argennonToken)
    GovernanceSystem(
        _admin,
        _argennonToken,
        VotingConfig({
            proposalFee : INITIAL_PROPOSAL_FEE,
            lockDuration : INITIAL_LOCK_DURATION,
            majorityPercent : INITIAL_MAJORITY_PERCENT
        })
    ) {}


    function createInitialCrowdfunding(TokenSaleConfig calldata config) onlyBy(admin) public {
        require(!initialCrowdfundingCreated, "already created");
        initialCrowdfundingCreated = true;
        TokenSale newTs = new TokenSale(admin, address(governanceToken), config);
        governanceToken.increaseMintingAllowance(address(newTs), config.totalSupply);
        emit TokenSaleCreated(newTs, abi.encode(admin, address(governanceToken), config));
    }
}
