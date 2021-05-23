// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const GovernanceSystem = artifacts.require("GovernanceSystem");
const GovernanceToken = artifacts.require("GovernanceTestToken");
const FiatToken = artifacts.require("LockableTestToken");
const Ballot = artifacts.require("Ballot"); 

contract("GovernanceSystem", (accounts) => {
    it("can handle a normal use case", async () => {
        const admin = accounts[9];
        const gToken = await GovernanceToken.new(admin);
        await gToken.mint(accounts[0], 1000, {from: admin});
        const gSystem = await GovernanceSystem.new(
            admin,
            gToken.address,
            {
                proposalFee: 1000,
                lockDuration:  3600 * 24 * 240,
                majorityPercent: 60
            }
        );
        await gToken.setOwner(gSystem.address, {from: admin});
        const deployTime = Math.floor(Date.now() / 1000);


        let ballotAddress = (await gSystem.proposeChangeOfSettings(
            accounts[1],
            {
                proposalFee: 2000,
                lockDuration:  3600 * 24 * 120,
                majorityPercent: 60
            },
            deployTime + 7,
            {from: accounts[0], value: 1000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);
        ballotAddress = (await gSystem.proposeChangeOfSettings(
            accounts[1],
            {
                proposalFee: 2000,
                lockDuration:  3600 * 24 * 120,
                majorityPercent: 60
            },
            deployTime + 7,
            {from: accounts[0], value: 1000}
        )).logs[0].args.newBallot;
        const ballotFail = await Ballot.at(ballotAddress);

        await gSystem.DecodeBallotAction(ballot.address);

        await gToken.setLock(800, deployTime + 6 + 3600 * 24 * 240, {from: accounts[0]})
        await Verifier.expectError(
            ballot.changeVoteTo(700, {from: accounts[0]}),
            Verifier.Ballot.LOCK_TOO_SHORT_ERROR
        )
        await gToken.setLock(800, deployTime + 7 + 3600 * 24 * 240, {from: accounts[0]})
        await ballot.changeVoteTo(700, {from: accounts[0]});
        await ballotFail.changeVoteTo(500, {from: accounts[0]});

        await Verifier.expectError(
            gSystem.executeProposal(ballot.address),
            Verifier.TOO_EARLY_ERROR
        );
        while (Math.floor(Date.now() / 1000) < deployTime + 9);

        await gSystem.executeProposal(ballotFail.address);
        assert.equal(
            (await gSystem.votingConfig.call()).proposalFee.valueOf(),
            1000,
            "error in proposal fee"
        );
        await Verifier.expectError(
            gSystem.DecodeBallotAction(ballotFail.address),
            Verifier.Governance.BALLOT_NOT_FOUND_ERROR
        );

        await gSystem.executeProposal(ballot.address);
        assert.equal(
            (await gSystem.votingConfig.call()).proposalFee.valueOf(),
            2000,
            "error in proposal fee"
        );
    });
});
