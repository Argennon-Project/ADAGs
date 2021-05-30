// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const ArgennonToken = artifacts.require("ArgennonToken");
const Ballot = artifacts.require("Ballot");

contract("Ballot", (accounts) => {
    const admin = accounts[9];
    const creator = accounts[8];
    let arg, ballot;
    let deployTime;

    beforeEach(async () => {
        arg = await ArgennonToken.new(admin, admin);
        await arg.mint(accounts[0], 1, {from: admin});
        await arg.mint(accounts[0], 99, {from: admin});
        deployTime = Math.floor(Date.now() / 1000);
        ballot = await Ballot.new(admin, arg.address, deployTime + 10, deployTime + 25, {from: creator});
    });

    it("checks constructor parameters", async () => {
        await Verifier.expectError(
            Ballot.new(admin, arg.address, deployTime - 1, deployTime + 25, {from: creator}),
            Verifier.Ballot.DATES_ERROR
        );
        await Verifier.expectError(
            Ballot.new(admin, arg.address, deployTime + 5, deployTime + 5, {from: creator}),
            Verifier.Ballot.DATES_ERROR
        );
        await Verifier.expectError(
            Ballot.new(admin, arg.address, deployTime + 5, deployTime - 5, {from: creator}),
            Verifier.Ballot.DATES_ERROR
        );
        ballot = await Ballot.new(admin, arg.address, deployTime + 5, deployTime + 6, {from: creator});
        assert.equal(
            (await ballot.admin.call()).valueOf(),
            admin,
            "admin is invalid"
        );
        assert.equal(
            (await ballot.parent.call()).valueOf(),
            creator,
            "creator is invalid"
        );
        assert.equal(
            (await ballot.endTime.call()).valueOf(),
            deployTime + 5,
            "endTime is invalid"
        );
        assert.equal(
            (await ballot.lockTime.call()).valueOf(),
            deployTime + 6,
            "lockTime is invalid"
        );
    });

    it("collects user votes", async () => {
        await arg.mint(accounts[0], 100, {from: admin});
        await arg.mint(accounts[1], 50, {from: admin});
        await arg.mint(accounts[2], 200, {from: admin});

        await arg.setLock(150, deployTime + 25, {from: accounts[0]});
        await arg.setLock(40, deployTime + 25, {from: accounts[1]});
        await arg.setLock(200, deployTime + 25, {from: accounts[2]});

        await ballot.changeVoteTo(100, {from: accounts[0]});
        await ballot.changeVoteTo(20, {from: accounts[1]});
        await ballot.changeVoteTo(150, {from: accounts[2]});
        await Verifier.check(ballot.votes.call, [100, 20, 150], accounts, true, "test_1", 1);
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            270,
            "error in total weight"
        );

        await ballot.changeVoteTo(50, {from: accounts[0]});
        await ballot.changeVoteTo(40, {from: accounts[1]});
        await ballot.changeVoteTo(200, {from: accounts[2]});
        await Verifier.check(ballot.votes.call, [50, 40, 200], accounts, true, "test_2", 1);
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            290,
            "error in total weight"
        );

        await ballot.changeVoteTo(10, {from: accounts[0]});
        await ballot.changeVoteTo(15, {from: accounts[1]});
        await ballot.changeVoteTo(50, {from: accounts[2]});
        await Verifier.check(ballot.votes.call, [10, 15, 50], accounts, true, "test_3", 1);
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            75,
            "error in total weight"
        );

        await ballot.changeVoteTo(100, {from: accounts[0]});
        await ballot.changeVoteTo(25, {from: accounts[1]});
        await Verifier.check(ballot.votes.call, [100, 25, 50], accounts, true, "test_4", 1);
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            175,
            "error in total weight"
        );
    });

    it("makes sure the user has locked his tokens", async () => {
        await Verifier.expectError(
            ballot.changeVoteTo(0, {from: accounts[0]}),
            Verifier.Ballot.LOCK_TOO_SHORT_ERROR
        );
        await arg.setLock(0, deployTime + 25, {from: accounts[0]});
        await ballot.changeVoteTo(0, {from: accounts[0]});
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            0,
            "error in total weight"
        );

        await arg.setLock(30, deployTime + 25);
        await Verifier.expectError(
            ballot.changeVoteTo(31, {from: accounts[0]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );
        await ballot.changeVoteTo(30, {from: accounts[0]});

        await arg.setLock(50, deployTime + 25, {from: accounts[1]});
        await arg.mint(accounts[1], 20, {from: admin});
        await Verifier.expectError(
            ballot.changeVoteTo(21, {from: accounts[1]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );
        await ballot.changeVoteTo(20, {from: accounts[1]});

        // bad lock time
        await arg.setLock(50, deployTime + 24, {from: accounts[2]});
        await arg.mint(accounts[2], 50, {from: admin});
        await Verifier.expectError(
            ballot.changeVoteTo(10, {from: accounts[2]}),
            Verifier.Ballot.LOCK_TOO_SHORT_ERROR
        );
        await arg.setLock(50, deployTime + 25, {from: accounts[2]});
        await ballot.changeVoteTo(10, {from: accounts[2]});

        await Verifier.expectError(
            ballot.changeVoteTo(31, {from: accounts[0]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );
        await Verifier.expectError(
            ballot.changeVoteTo(51, {from: accounts[2]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );

        await arg.setLock(40, deployTime + 25, {from: accounts[0]});
        await arg.mint(accounts[1], 10, {from: admin});
        await Verifier.expectError(
            ballot.changeVoteTo(41, {from: accounts[0]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );
        await Verifier.expectError(
            ballot.changeVoteTo(31, {from: accounts[1]}),
            Verifier.Ballot.NOT_ENOUGH_LOCKED_ERROR
        );
        await ballot.changeVoteTo(40, {from: accounts[0]});
        await ballot.changeVoteTo(30, {from: accounts[1]});
        assert.equal(
            (await ballot.totalWeight.call()).valueOf(),
            80,
            "error in total weight"
        );
    });

    it("checks the end time", async () => {
        ballot = await Ballot.new(admin, arg.address, deployTime + 4, deployTime + 8);
        await arg.mint(accounts[0], 100, {from: admin});
        await arg.setLock(100, deployTime + 8, {from: accounts[0]});
        await ballot.changeVoteTo(100, {from: accounts[0]});
        await ballot.changeVoteTo(100, {from: accounts[0]});

        while (Math.floor(Date.now() / 1000) < deployTime + 6);

        await Verifier.expectError(
            ballot.changeVoteTo(100, {from: accounts[0]}),
            Verifier.TOO_LATE_ERROR
        )
    });

    it("only allows its parent to destroy it", async () => {
        await Verifier.expectError(
            ballot.destroy({from: accounts[0]}),
            Verifier.NOT_AUTHORIZED_ERROR
        );

        await ballot.destroy({from: creator});
    });
});

