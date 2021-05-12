// SPDX-License-Identifier: AGPL-3.0-only

const Errors = require('./errors.js');
const LockableTestToken = artifacts.require("LockableTestToken");

contract("LockableERC20", (accounts) => {

    let lockableToken;

    beforeEach(async () => {
        lockableToken = await LockableTestToken.new(accounts[0], 1000);
    });

    it("should lock tokens even before getting them", async () => {
        const timestamp = Math.floor(Date.now() / 1000) + 200;
        await lockableToken.setLock(300, timestamp, {from: accounts[1]});

        await lockableToken.transfer(accounts[1], 200, {from: accounts[0]});
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[1])).toNumber(),
            200,
            "200 was not transferred"
        );

        const lock = await lockableToken.locked.call(accounts[1]);
        assert.equal(lock.amount.valueOf(), 200, "Amount of lock should be 200");
        assert.equal(lock.releaseTime.valueOf(), timestamp, "Release time was not correct");

        await Errors.expectError(
            lockableToken.transfer(accounts[0], 100, {from: accounts[1]}),
            Errors.LOCKED_ERROR
        );
    });

    it("should only extend locks", async () => {
        await lockableToken.transfer(accounts[1], 200, {from: accounts[0]});
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[1])).toNumber(),
            200,
            "200 was not transferred"
        );

        await lockableToken.setLock(200, Math.floor(Date.now() / 1000) - 1000, {from: accounts[1]});
        lockableToken.transfer(accounts[2], 100, {from: accounts[1]});
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[2])).toNumber(),
            100,
            "100 was not transferred"
        );
        await lockableToken.setLock(200, Math.floor(Date.now() / 1000) - 1000, {from: accounts[1]});
        await lockableToken.setLock(50, Math.floor(Date.now() / 1000) + 1000, {from: accounts[1]});
        await lockableToken.setLock(150, Math.floor(Date.now() / 1000) + 1000, {from: accounts[1]});
        await Errors.expectError(
            lockableToken.setLock(200, Math.floor(Date.now() / 1000) + 900, {from: accounts[1]}),
            Errors.LOCK_UPDATE_ERROR
        );

        await lockableToken.transfer(accounts[1], 100, {from: accounts[0]});
        // first transfer should be successful.
        await lockableToken.transfer(accounts[2], 50, {from: accounts[1]});
        await Errors.expectError(
            lockableToken.transfer(accounts[2], 1, {from: accounts[1]}),
            Errors.LOCKED_ERROR
        );
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[2])).toNumber(),
            150,
            "Error in acc2's final balance"
        );
    });
});
