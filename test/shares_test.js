// SPDX-License-Identifier: GPL-3.0-or-later

const Errors = require('./errors.js');
const DistributorToken = artifacts.require("DistributorTestToken");
const TestToken = artifacts.require("LockableTestToken");

contract("DistributorERC20", (accounts) => {

    let sharesToken, fiatToken, admin;

    beforeEach(async () => {
        admin = accounts[0];
        sharesToken = await DistributorToken.new(admin, 1000);
        fiatToken = await TestToken.new(admin, 100000000000);
        await sharesToken.registerProfitSource(fiatToken.address);
    });

    async function checkProfits(profits, sourceIndex) {
        for (let i = 0; i < profits.length; i++) {
            assert.equal(
                (await sharesToken.profit.call(accounts[i], sourceIndex)).valueOf(),
                profits[i],
                `acc${i} profit is wrong`
            );
        }
    }

    it("distributes profits based on account balances", async () => {
        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        const decimals = 1000000000;
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});

        await checkProfits([7, 1, 2] * decimals, 0);

        await sharesToken.withdrawProfit(decimals, 0, {from: accounts[2]});
        await sharesToken.transfer(admin, 50, {from: accounts[2]});
        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});

        await sharesToken.transfer(accounts[1], 300, {from: admin});
        await sharesToken.withdrawProfit(3 * decimals, 0, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});

        await fiatToken.transfer(sharesToken.address, 5 * decimals, {from: admin});

        await checkProfits([45, 25, 30] * decimals / 10, 0);

        await sharesToken.withdrawProfit(decimals, 0, {from: accounts[2]});
        assert.equal(
            (await fiatToken.balanceOf.call(accounts[2])).valueOf(),
            2 * decimals,
            "Error in acc2 final balance"
        );
    });
});

