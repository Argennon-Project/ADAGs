// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const GovernanceSystem = artifacts.require("GovernanceSystem");
const GovernanceToken = artifacts.require("GovernanceTestToken");
const FiatToken = artifacts.require("LockableTestToken");
const Ballot = artifacts.require("Ballot"); 

contract("GovernanceSystem", (accounts) => {
    const admin = accounts[9];
    let gSystem, gToken;
    let deployTime;

    beforeEach(async () => {
        gToken = await GovernanceToken.new(admin);
        await gToken.mint(accounts[0], 1000, {from: admin});

        gSystem = await GovernanceSystem.new(
            admin,
            gToken.address,
            {
                proposalFee: 1000,
                lockDuration:  3600 * 24 * 240,
                majorityPercent: 70
            }
        );
        await gToken.setOwner(gSystem.address, {from: admin});
        deployTime = Math.floor(Date.now() / 1000);
        await gToken.setLock(1000, deployTime + 1000 + 3600 * 24 * 240, {from: accounts[0]});
    });

    it("creates a ballot for a proposal", async () => {
        await Verifier.expectError(
            gSystem.proposeMintApproval(accounts[1], 100, deployTime - 1, {from: accounts[0], value: 1000}),
            Verifier.Ballot.DATES_ERROR
        );

        await Verifier.expectError(
            gSystem.proposeMintApproval(accounts[1], 100, deployTime + 5, {from: accounts[0], value: 900}),
            Verifier.Governance.FEE_ERROR
        );

        let ballotAddress = (await gSystem.proposeMintApproval(
            accounts[1], 100,
            deployTime + 5,
            {from: accounts[0], value: 2000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);

        assert.equal(
            (await ballot.endTime.call()).valueOf(),
            deployTime + 5,
            "error in endTime"
        );
        assert.equal(
            (await ballot.lockTime.call()).valueOf(),
            deployTime + 5 + 3600 * 24 * 240,
            "error in lockTime"
        );
        assert.equal(
            (await ballot.votingToken.call()).valueOf(),
            gToken.address,
            "error in votingToken"
        );
        assert.equal(
            (await ballot.parent.call()).valueOf(),
            gSystem.address,
            "error in parent"
        );
        assert.equal(
            (await ballot.admin.call()).valueOf(),
            admin,
            "error in admin"
        );
    });

    it("can execute a proposal", async () => {
        const orphanBallot = await Ballot.new(admin, gToken.address, deployTime + 5, deployTime + 6, {from: admin});
        await Verifier.expectError(
            gSystem.executeProposal(orphanBallot.address),
            Verifier.Governance.BALLOT_NOT_FOUND_ERROR
        )

        let ballotAddress = (await gSystem.proposeChangeOfSettings(
            accounts[1],
            {
                proposalFee: 2000,
                lockDuration:  3600 * 24 * 120,
                majorityPercent: 60
            },
            deployTime + 5,
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
            deployTime + 5,
            {from: accounts[0], value: 1000}
        )).logs[0].args.newBallot;
        const earlyBallot = await Ballot.at(ballotAddress);

        await Verifier.expectError(
            gSystem.executeProposal(earlyBallot.address),
            Verifier.TOO_EARLY_ERROR
        );

        await earlyBallot.changeVoteTo(700, {from: accounts[0]});
        await ballot.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 7);

        await gSystem.executeProposal(earlyBallot.address);
        await Verifier.expectError(
            gSystem.executeProposal(earlyBallot.address),
            Verifier.Governance.BALLOT_NOT_FOUND_ERROR
        );
        assert.equal(
            (await gSystem.votingConfig.call()).proposalFee.valueOf(),
            1000,
            "error in proposal fee"
        );

        await gSystem.executeProposal(ballot.address);
        await Verifier.expectError(
            gSystem.DecodeBallotAction(ballot.address),
            Verifier.Governance.BALLOT_NOT_FOUND_ERROR
        );
        assert.equal(
            (await gSystem.votingConfig.call()).proposalFee.valueOf(),
            2000,
            "error in proposal fee"
        );
    });

    // In the following unit tests for specific governance actions we only test the main scenario. we don't need to
    // test for alternative scenarios because we have already tested them in ballot tests or other governance tests.
    it("can mint governance token", async () => {
        let ballotAddress = (await gSystem.proposeMinting(
            accounts[5], 100,
            deployTime + 2,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);
        await ballot.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 3);

        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            0,
            "error in acc5 balance"
        );
        await gSystem.executeProposal(ballot.address);
        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            2100,
            "error in minting for acc5"
        );
    });

    it("can give mint allowance", async () => {

    });

    it("can give grants", async () => {

    });

    it("can reset the admin of other contracts", async () => {

    });

    it("can start a new token sale", async () => {

    });

    it("can retire itself", async () => {

    });


});
