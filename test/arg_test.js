// SPDX-License-Identifier: AGPL-3.0-only

const Errors = require("./verifier");
const Argennon = artifacts.require("ArgennonToken");
const FiatToken = artifacts.require("LockableTestToken");

contract("ArgennonToken", (accounts) => {
    const decimals = 1000000;
    let owner, admin;
    let arg, fiat;

    beforeEach(async () => {
        owner = accounts[0];
        admin = accounts[1];
        arg = await Argennon.new(admin, owner);
        fiat = await FiatToken.new(admin , 1000000 * decimals);
    });

    async function checkProfitsNonExact(profits, sharesToken, sourceIndex, name) {
        await Errors.check(
            (x) => {
                return sharesToken.balanceOfProfit.call(x, sourceIndex)
            },
            profits,
            accounts,
            false,
            name,
            decimals
        );
    }

    it("can handle a normal use case", async () => {
        await arg.mint(accounts[1], 300 * decimals * decimals, {from: admin});
        await arg.mint(accounts[2], 200 * decimals * decimals, {from: admin});
        await arg.registerProfitSource(fiat.address, {from: admin});
        await arg.mint(accounts[0], 500 * decimals * decimals, {from: admin});
        await Errors.expectError(
            arg.mint(accounts[2], 1, {from: admin}),
            Errors.Mintable.MINT_ALLOWANCE_ERROR
        );

        // balances: [500 300 200 (5000)] -> [100 60 40 (1000)]
        await fiat.transfer(arg.address, 1200 * decimals, {from: admin});

        await Errors.expectError(
            arg.transfer(accounts[3], 4000, {from: accounts[0]}),
            Errors.PRECISION_ERROR
        );

        await arg.transfer(accounts[3], decimals, {from: accounts[0]});
        await arg.transfer(accounts[3], 5 * decimals, {from: accounts[0]});
        await arg.transfer(accounts[3], 400 * decimals * decimals - 6 * decimals, {from: accounts[0]});
        await arg.mint(accounts[4], 300 * decimals * decimals, {from: owner});
        await checkProfitsNonExact([100, 60, 40, 0, 0], arg, 0, "initial");

        await arg.transfer(accounts[2], 0.1 * decimals, {from: accounts[4]});
        await arg.transfer(accounts[2], 0.9 * decimals, {from: accounts[4]});
        await arg.transfer(accounts[2], 2 * decimals, {from: accounts[4]});
        await arg.transfer(accounts[2], 2 * decimals, {from: accounts[4]});
        await arg.transfer(accounts[2], 200 * decimals * decimals - 5 * decimals, {from: accounts[4]});
        await arg.withdrawProfit(60 * decimals, 0, {from: accounts[1]});


        await arg.transfer(accounts[0], 100 * decimals * decimals, {from: accounts[1]});
        await arg.mint(accounts[1], 200 * decimals * decimals, {from: owner});
        await arg.withdrawProfit(50 * decimals, 0, {from: accounts[0]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[0])).valueOf(),
            50 * decimals,
            "Error in acc0 profit withdrawal"
        );
        await arg.transfer(accounts[1], 100 * decimals * decimals, {from: accounts[0]});
        await arg.transfer(accounts[5], 100 * decimals * decimals, {from: accounts[0]});
        // balances: [0 500 400 400 100 100(5000)] -> [50 50 80 40 10 10 (500)]
        await fiat.transfer(arg.address, 650 * decimals, {from: admin});
        await arg.mint(accounts[0], 400 * decimals * decimals, {from: owner});
        await checkProfitsNonExact([50, 50, 80, 40, 10, 10], arg, 0, "after_withdrawal");

        await arg.excludeFromProfits(accounts[0], {from: admin});
        await arg.mint(accounts[0], 100 * decimals * decimals, {from: owner});
        await arg.transfer(accounts[0], 100 * decimals * decimals, {from: accounts[2]});
        await arg.withdrawProfit(10 * decimals, 0, {from: accounts[0]});
        await arg.transfer(accounts[5], 200 * decimals * decimals, {from: accounts[0]});
        // [400 500 300 400 100 300] -> [80 100 60 80 20 60] (1000)
        await fiat.transfer(arg.address, 1400 * decimals, {from: admin});
        await arg.mint(accounts[4], 1000 * decimals * decimals, {from: owner});
        await arg.transfer(accounts[3], 400 * decimals * decimals, {from: accounts[0]});
        // [0 500 300 800 1100 300] -> [0 7.5 4.5 12 16.5 4.5 (75)]
        await checkProfitsNonExact([0, 157.5, 144.5, 132, 46.5, 74.5], arg, 0, "after_exclude");

        await Errors.expectError(
            arg.withdrawProfit(2n ** 256n - 10n, 1, {from: accounts[1]}),
            Errors.GENERAL_ERROR
        );
        await Errors.expectError(
            arg.withdrawProfit(2n ** 256n - 10n, 0, {from: accounts[1]}),
            Errors.LOW_BALANCE_ERROR
        );
        await Errors.expectError(
            arg.withdrawProfit(145 * decimals, 0, {from: accounts[2]}),
            Errors.LOW_BALANCE_ERROR
        );

        await Errors.expectError(
            arg.registerProfitSource(accounts[6], {from: admin}),
            Errors.GENERAL_ERROR
        );

        assert.equal(
            (await arg.balanceOf.call(accounts[3])).valueOf(),
            800 * decimals * decimals,
            "Error in acc3 balance"
        );
        const timestamp = Math.floor(Date.now() / 1000);
        await arg.setLock(200 * decimals * decimals, timestamp + 5, {from: accounts[5]});
        await arg.transfer(accounts[3], 100 * decimals * decimals, {from: accounts[5]});
        await Errors.expectError(
            arg.transfer(accounts[3], 100 * decimals * decimals, {from: accounts[5]}),
            Errors.LOCKED_ERROR
        );
        while (Math.floor(Date.now() / 1000) < timestamp + 8);
        await arg.transfer(accounts[3], 100 * decimals * decimals, {from: accounts[5]});
        assert.equal(
            (await arg.balanceOf.call(accounts[3])).valueOf(),
            1000 * decimals * decimals,
            "Error in locked tokens transfer"
        );

        await Errors.expectError(
            arg.mint(accounts[5], 100 * decimals, {from: accounts[6]}),
            Errors.Mintable.MINT_ALLOWANCE_ERROR
        );
        await Errors.expectError(
            arg.setOwner(accounts[5], {from: accounts[6]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await arg.setOwner(accounts[6], {from: owner});
        await Errors.expectError(
            arg.setOwner(accounts[4], {from: owner}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        owner = accounts[6];

        await arg.transfer(accounts[2], 450 * decimals * decimals, {from: accounts[1]});
        await arg.transfer(accounts[0], 100 * decimals * decimals, {from: accounts[5]});
        await arg.mint(accounts[0], 100 * decimals * decimals, {from: owner});
        await arg.mint(accounts[4], 900 * decimals * decimals, {from: owner});
        // [200 50 750 1000 2000 0] -> [20 5 75 100 200 0] 500
        await fiat.transfer(arg.address, 900 * decimals, {from: admin});
        await arg.mint(accounts[5], 500 * decimals * decimals, {from: owner});
        await arg.mint(accounts[0], 500 * decimals * decimals, {from: owner});
        await arg.transfer(accounts[1], 400 * decimals * decimals, {from: accounts[3]});
        await Errors.expectError(
            arg.mint(accounts[5], 10000, {from: owner}),
            Errors.Mintable.EXCEEDS_MAX_SUPPLY_ERROR
        );
        assert.equal(
            (await arg.totalSupply.call()).valueOf(),
            10000 * decimals * decimals,
            "Error in totalSupply"
        );
        await checkProfitsNonExact([20, 162.5, 219.5, 232, 246.5, 74.5], arg, 0, "final_1");
        await arg.withdrawProfit(10 * decimals, 0, {from: accounts[0]});
        await arg.transfer(accounts[0], 200 * decimals * decimals, {from: accounts[3]});
        //  [0 450 750 400 2000 1400] -> [0 0.45 0.75 0.4 2 1.4] 5
        await arg.transfer(accounts[5], 900 * decimals * decimals, {from: accounts[0]});
        await checkProfitsNonExact([0, 162.95, 220.25, 232.4, 248.5, 75.9],
            arg, 0, "after excluded withdraw");

        await arg.transfer(accounts[0], 500 * decimals * decimals, {from: accounts[4]});
        await arg.withdrawProfit(100 * decimals, 0, {from: accounts[4]});
        await arg.withdrawProfit(50 * decimals, 0, {from: accounts[3]});
        await arg.transfer(accounts[1], 200 * decimals * decimals, {from: accounts[5]});
        // [500 650 750 400 1500 1200] - > [5 6.5 7.5 4 15 12] 50
        await fiat.transfer(arg.address, 100 * decimals, {from: admin});
        await checkProfitsNonExact([5, 169.45, 227.75, 186.4, 163.5, 87.9], arg, 0, "final_2");
    });

    it("can handle arithmetic errors", async () => {
        await arg.mint(accounts[1], 400 * decimals * decimals, {from: admin});
        await arg.mint(accounts[2], 100 * decimals * decimals, {from: admin});
        await arg.registerProfitSource(fiat.address, {from: admin});
        await fiat.transfer(arg.address, 1100 * decimals, {from: admin});
        await checkProfitsNonExact([0, 80, 20], arg, 0, "initial");
        for (let i = 0; i < 300; i++) {
            // 2e6 is a very good choice that gives 0.4 error
            await arg.transfer(accounts[2], 2 * decimals, {from: accounts[1]});
        }
        await checkProfitsNonExact([0, 80, 20], arg, 0, "after transfer");
    });
});


