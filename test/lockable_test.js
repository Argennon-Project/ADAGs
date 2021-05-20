// SPDX-License-Identifier: AGPL-3.0-only

const Errors = require("./verifier");
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
        const timestamp = Math.floor(Date.now() / 1000);
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[1])).toNumber(),
            200,
            "200 was not transferred"
        );

        await lockableToken.setLock(200, timestamp - 1000, {from: accounts[1]});
        let lockData = await lockableToken.locksData.call(accounts[1]);
        assert.equal(lockData.threshold.valueOf(), 200, "lock threshold should be 200");
        assert.equal(lockData.releaseTime.valueOf(), timestamp - 1000, "Release time was not correct");

        lockableToken.transfer(accounts[2], 100, {from: accounts[1]});
        assert.equal(
            (await lockableToken.balanceOf.call(accounts[2])).toNumber(),
            100,
            "100 was not transferred"
        );
        await lockableToken.setLock(150, timestamp - 2000, {from: accounts[1]});
        lockData = await lockableToken.locksData.call(accounts[1]);
        assert.equal(lockData.threshold.valueOf(), 150, "lock threshold should be 150");
        assert.equal(lockData.releaseTime.valueOf(), timestamp - 2000, "Release time was not correct");


        await lockableToken.setLock(50, timestamp + 1000, {from: accounts[1]});
        await lockableToken.setLock(150, timestamp + 1000, {from: accounts[1]});
        await lockableToken.setLock(150, timestamp + 1500, {from: accounts[1]});
        await Errors.expectError(
            lockableToken.setLock(200, timestamp + 1400, {from: accounts[1]}),
            Errors.LOCK_UPDATE_ERROR
        );
        await Errors.expectError(
            lockableToken.setLock(140, timestamp + 2000, {from: accounts[1]}),
            Errors.LOCK_UPDATE_ERROR
        );
        let lock = await lockableToken.locked.call(accounts[1]);
        assert.equal(lock.amount.valueOf(), 100, "Amount of lock should be 100");
        assert.equal(lock.releaseTime.valueOf(), timestamp + 1500, "Release time was not correct");

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
        lockData = await lockableToken.locksData.call(accounts[1]);
        assert.equal(lockData.threshold.valueOf(), 150, "Amount of lock should be 150");
        assert.equal(lockData.releaseTime.valueOf(), timestamp + 1500, "Release time was not correct");
    });
});
