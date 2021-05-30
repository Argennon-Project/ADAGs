// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const GovernanceSystem = artifacts.require("GovernanceSystem");
const GovernanceToken = artifacts.require("GovernanceTestToken");
const ArgToken = artifacts.require("ArgennonToken");
const Ballot = artifacts.require("Ballot");
const TokenSale = artifacts.require("TokenSale");

contract("GovernanceSystem", (accounts) => {
    const admin = accounts[9];
    let gSystem, gToken;
    let deployTime;

    beforeEach(async () => {
        gToken = await GovernanceToken.new(admin, admin);
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
        await gToken.setLock(800, deployTime + 1000 + 3600 * 24 * 240, {from: accounts[0]});
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

        while (Math.floor(Date.now() / 1000) < deployTime + 4);

        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            0,
            "error in acc5 balance"
        );
        await gSystem.executeProposal(ballot.address);
        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            100,
            "error in minting for acc5"
        );
    });

    it("can give mint allowance", async () => {
        let ballotAddress = (await gSystem.proposeMintApproval(
            accounts[5], 200,
            deployTime + 2,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);
        await ballot.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 4);

        assert.equal(
            (await gToken.mintingAllowances.call(accounts[5])).valueOf(),
            0,
            "error in acc5 mint allowance"
        );

        await gSystem.executeProposal(ballot.address);

        assert.equal(
            (await gToken.mintingAllowances.call(accounts[5])).valueOf(),
            200,
            "error in acc5 mint allowance"
        );
        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            0,
            "error in acc5 balance"
        );
        await gToken.mint(accounts[5], 200, {from: accounts[5]});
        await Verifier.expectError(
            gToken.mint(accounts[5], 1, {from: accounts[5]}),
            Verifier.Mintable.MINT_ALLOWANCE_ERROR
        );
        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            200,
            "error in minting for acc5"
        );
    });

    it("can give grants", async () => {
        let ballotAddress = (await gSystem.proposeGrant(
            accounts[5], 15000, "0x0000000000000000000000000000000000000000",
            deployTime + 2,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);
        await ballot.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 4);

        await gSystem.send(15000);

        const balanceBefore = BigInt(await web3.eth.getBalance(accounts[5]));
        await gSystem.executeProposal(ballot.address);
        const balanceAfter = BigInt(await web3.eth.getBalance(accounts[5]));
        assert.equal(
            balanceAfter - balanceBefore,
            15000,
            "error in eth grant"
        );

        ballotAddress = (await gSystem.proposeGrant(
            accounts[5], 200, gToken.address,
            deployTime + 5,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballot2 = await Ballot.at(ballotAddress);
        await ballot2.changeVoteTo(701, {from: accounts[0]});
        await gToken.transfer(gSystem.address, 200, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 7);

        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            0,
            "error in acc5 token balance"
        );
        await gSystem.executeProposal(ballot2.address);
        assert.equal(
            (await gToken.balanceOf.call(accounts[5])).valueOf(),
            200,
            "error in token grant"
        );
    });

    it("can reset the admin of other contracts", async () => {
        await Verifier.expectError(
            gSystem.proposeAdminReset(accounts[0], deployTime + 2, {from: accounts[2], value: 1000}),
            Verifier.GENERAL_ERROR
        );

        await Verifier.expectError(
            gSystem.proposeAdminReset(gToken.address, deployTime + 2, {from: accounts[2], value: 1000}),
            Verifier.Governance.TARGET_ADMIN_ERROR
        );

        await gToken.setAdmin(gSystem.address, {from: admin});
        let ballotAddress = (await gSystem.proposeAdminReset(
            gToken.address,
            deployTime + 2,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballot = await Ballot.at(ballotAddress);
        await ballot.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 4);

        assert.equal(
            (await gToken.admin.call()),
            gSystem.address,
            "invalid admin before"
        );
        await gSystem.executeProposal(ballot.address);
        assert.equal(
            (await gToken.admin.call()),
            admin,
            "invalid admin after"
        );
    });

    it("can start a new token sale", async () => {
        const fiat = await GovernanceToken.new(accounts[6], accounts[6]);
        await gToken.registerProfitSource(fiat.address, {from: admin});

        const forSale = await ArgToken.new(admin, gSystem.address);

        const normalConfig = {
            name: "test ICO",
            symbol: "TST_ICO",
            redemptionDuration: 3600 * 24 * 15,
            minFiatForActivation: 1000,
            totalSupply: 5e14,
            redemptionRatio: {a: 80, b: 100},
            price: {a: 1, b: 10000},
            fiatTokenContract: fiat.address,
            originalToken: forSale.address
        };

        const invalidPrice = {...normalConfig};
        invalidPrice.price = {a: 0, b: 1000};
        await Verifier.expectError(
            gSystem.proposeTokenSale(invalidPrice, true, deployTime + 2, {from: accounts[2], value: 2000}),
            Verifier.TokenSale.ZERO_PRICE_ERROR
        );

        const invalidFiat = {...normalConfig};
        invalidFiat.fiatTokenContract = accounts[7];
        await Verifier.expectError(
            gSystem.proposeTokenSale(invalidFiat, false, deployTime + 2, {from: accounts[2], value: 2000}),
            Verifier.Governance.FIAT_ERROR
        );

        const invalidOriginal = {...normalConfig};
        invalidOriginal.originalToken = accounts[7];
        await Verifier.expectError(
            gSystem.proposeTokenSale(invalidOriginal, false, deployTime + 2, {from: accounts[2], value: 2000}),
            Verifier.GENERAL_ERROR
        );

        invalidOriginal.originalToken = (await ArgToken.new(admin, admin)).address;
        await Verifier.expectError(
            gSystem.proposeTokenSale(invalidOriginal, false, deployTime + 2, {from: accounts[2], value: 2000}),
            Verifier.NOT_AUTHORIZED_ERROR
        );

        let ballotAddress = (await gSystem.proposeTokenSale(
            normalConfig,
            true,
            deployTime + 3,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballotGs = await Ballot.at(ballotAddress);
        await ballotGs.changeVoteTo(701, {from: accounts[0]});

        ballotAddress = (await gSystem.proposeTokenSale(
            normalConfig,
            false,
            deployTime + 4,
            {from: accounts[2], value: 2000}
        )).logs[0].args.newBallot;
        const ballotArg = await Ballot.at(ballotAddress);
        await ballotArg.changeVoteTo(701, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 5);

        await gSystem.executeProposal(ballotGs.address);
        const saleGs = await TokenSale.at(await gSystem.tokenSales.call(0));
        Verifier.checkStruct(normalConfig, await saleGs.config.call(), "test GS");
        assert.equal(
            (await saleGs.beneficiary.call()),
            gSystem.address,
            "beneficiary should be GS"
        );
        assert.equal(
            (await forSale.mintingAllowances.call(saleGs.address)).valueOf(),
            normalConfig.totalSupply,
            "error in GS mint allowance"
        );

        await gSystem.executeProposal(ballotArg.address);
        const saleArg = await TokenSale.at(await gSystem.tokenSales.call(1));
        Verifier.checkStruct(normalConfig, await saleArg.config.call(), "test ARG");
        assert.equal(
            (await saleArg.beneficiary.call()),
            gToken.address,
            "beneficiary should be gToken"
        );
        assert.equal(
            (await forSale.mintingAllowances.call(saleArg.address)).valueOf(),
            normalConfig.totalSupply,
            "error in ARG mint allowance"
        );
    });

    it("can change its settings", async () => {

    });

    it("can retire itself", async () => {

    });


});
