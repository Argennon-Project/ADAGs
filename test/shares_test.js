// SPDX-License-Identifier: GPL-3.0-or-later

const Errors = require('./errors.js');
const DistributorToken = artifacts.require("DistributorTestToken");
const TestToken = artifacts.require("LockableTestToken");

contract("DistributorERC20", (accounts) => {

    let sharesToken, fiatToken, admin;
    const decimals = 1000000000;

    beforeEach(async () => {
        admin = accounts[0];
        sharesToken = await DistributorToken.new(admin);
        await sharesToken.mint(admin, 1000);
        fiatToken = await TestToken.new(admin, 100 * decimals);
        await sharesToken.registerProfitSource(fiatToken.address, {from: admin});
    });

    async function checkProfits(profits, sourceIndex, name) {
        for (let i = 0; i < profits.length; i++) {
            assert.equal(
                (await sharesToken.profit.call(accounts[i], sourceIndex)).valueOf(),
                Math.round(profits[i] * decimals),
                `In ${name}, the profit of acc${i} is wrong`
            );
        }
    }

    it("allows admin to register new profit sources and recover funds", async () => {
        await Errors.expectError(
            sharesToken.registerProfitSource(fiatToken.address, {from: accounts[1]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await sharesToken.registerProfitSource(accounts[1], {from: admin});
        await sharesToken.registerProfitSource(accounts[2], {from: admin});
        await sharesToken.registerProfitSource(accounts[3], {from: admin});
        await Errors.expectError(
            sharesToken.registerProfitSource(accounts[2], {from: admin}),
            Errors.ALREADY_REGISTERED_ERROR
        );

        await Errors.expectError(
            sharesToken.recoverFunds(accounts[3], 100, {from: admin}),
            Errors.WITHDRAW_NOT_ALLOWED_ERROR
        );

        const testToken = await TestToken.new(admin, 10 * decimals);
        await testToken.transfer(sharesToken.address, 2 * decimals, {from: admin});
        assert.equal(
            (await testToken.balanceOf.call(admin)).valueOf(),
            8 * decimals,
            "Error in transfer"
        );
        await Errors.expectError(
            sharesToken.recoverFunds(testToken.address, 2 * decimals, {from: accounts[1]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await sharesToken.recoverFunds(testToken.address, 2 * decimals, {from: admin});
        assert.equal(
            (await testToken.balanceOf.call(admin)).valueOf(),
            10 * decimals,
            "Error in admin final balance"
        );
    });

    it("enables users to withdraw their profit", async () => {
        await sharesToken.transfer(accounts[1], 600, {from: admin});

        await fiatToken.transfer(sharesToken.address, 15 * decimals, {from: admin});

        await Errors.expectError(
            sharesToken.withdrawProfit(10 * decimals, 0, {from: accounts[1]}),
            Errors.LOW_BALANCE_ERROR
        );
        await sharesToken.withdrawProfit(9 * decimals, 0, {from: accounts[1]});
        await Errors.expectError(
            sharesToken.withdrawProfit(1, 0, {from: accounts[1]}),
            Errors.LOW_BALANCE_ERROR
        );
        assert.equal(
            (await fiatToken.balanceOf.call(accounts[1])).valueOf(),
            9 * decimals,
            "Error in acc1 final balance"
        );
    });

    it("distributes profits based on account balances", async () => {
        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});

        await checkProfits([7, 1, 2] , 0);

        await sharesToken.withdrawProfit(decimals, 0, {from: accounts[2]});
        await sharesToken.transfer(admin, 50, {from: accounts[2]});
        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});

        await sharesToken.transfer(accounts[1], 300, {from: admin});
        await sharesToken.withdrawProfit(3 * decimals, 0, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});

        await fiatToken.transfer(sharesToken.address, 5 * decimals, {from: admin});

        await checkProfits([5.5, 2.5, 3], 0, "final");

        await sharesToken.withdrawProfit(decimals, 0, {from: accounts[2]});
        assert.equal(
            (await fiatToken.balanceOf.call(accounts[2])).valueOf(),
            2 * decimals,
            "Error in acc2 final balance"
        );
    });

    it("should not give profits to newly minted tokens", async () => {
        sharesToken = await DistributorToken.new(admin);
        await sharesToken.registerProfitSource(fiatToken.address, {from: admin});
        assert.equal(
            (await sharesToken.totalSupply.call()).valueOf(),
            0,
            "cant reinitialize token"
        );

        await sharesToken.mint(admin, 500);
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await sharesToken.mint(accounts[1], 1000);
        await checkProfits([10, 0], 0, "check1");

        await fiatToken.transfer(sharesToken.address, 6 * decimals, {from: admin});
        await sharesToken.mint(accounts[2], 300);
        await checkProfits([12, 4, 0], 0, "check2");

        await sharesToken.withdrawProfit(4 * decimals, 0, {from: admin});
        await sharesToken.withdrawProfit(2 * decimals, 0, {from: accounts[1]});
        // profits: [8, 2, 0]
        await sharesToken.transfer(accounts[2], 200, {from: admin});
        await sharesToken.transfer(admin, 400, {from: accounts[1]});
        // balances: [700, 600, 500]
        await fiatToken.transfer(sharesToken.address, 9 * decimals, {from: admin});
        // gained profits: [3.5, 3, 2.5]
        await sharesToken.mint(accounts[3], 750);
        await checkProfits([11.5, 5, 2.5, 0], 0, "check3");
    });

    it("can exclude accounts from getting profits", async () => {
        await sharesToken.transfer(accounts[1], 400, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await Errors.expectError(
            sharesToken.excludeFromProfits(accounts[1], {from: accounts[1]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await sharesToken.excludeFromProfits(accounts[1], {from: admin});

        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await checkProfits([4, 4, 2], 0, "initial_basic");

        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[2], 500, {from: accounts[1]});
        // balance: [3, 0, 7] gained: [1.2, 0, 2.8]
        await checkProfits([5.2, 0, 4.8], 0, "basic");

        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[1], 200, {from: accounts[2]});
        await fiatToken.transfer(sharesToken.address, 5 * decimals, {from: admin});
        // balance: [2, 3, 5] gained: [1, 1.5, 2.5]
        await sharesToken.transfer(accounts[1], 200, {from: accounts[2]});
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await checkProfits([6.2, 1.5, 7.3], 0, "initial_advanced");
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 200, {from: accounts[1]});
        await checkProfits([6.2, 1.5, 7.3], 0, "initial_advanced_r");

        await sharesToken.transfer(accounts[2], 100, {from: admin});
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        // gained: (1 - 1.9 / 3) * 0.15 * [3.5, 0.5, 6] = [0.1925, ..]
        await checkProfits([6.3925, 0.9775, 7.63], 0, "advanced_1");

        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await checkProfits([6.3925, 0.9775, 7.63], 0, "advanced_1_r");
        // gained: 0.09775 * [4.5, 0, 5.5] = [0.439875, 0, 0.537625]
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await checkProfits([6.832375, 0, 8.167625], 0, "advanced_2");
    });

    it('can handle minting and transferring', async () => {
        sharesToken = await DistributorToken.new(admin);
        await sharesToken.registerProfitSource(sharesToken.address, {from: admin}); // register a dummy source
        await sharesToken.registerProfitSource(fiatToken.address, {from: admin});
        assert.equal(
            (await sharesToken.totalSupply.call()).valueOf(),
            0,
            "cant reinitialize token"
        );

        await sharesToken.mint(admin, 500);
        await sharesToken.mint(accounts[1], 300);
        await sharesToken.transfer(accounts[2], 100, {from: admin});
        await fiatToken.transfer(sharesToken.address, 8 * decimals, {from: admin});
        await checkProfits([4, 3, 1], 1, "initial");

        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 100, {from: accounts[1]});
        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});
        // balance: [5 1.5 1.5] -> [2.5 0.75 0.75]
        await fiatToken.transfer(sharesToken.address, 4 * decimals, {from: admin});
        await sharesToken.mint(accounts[1], 50);
        await sharesToken.mint(accounts[2], 150);
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await checkProfits([6.5, 3.75, 1.75], 1, "mint_1");

        // balance: [5 1 4]
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await sharesToken.transfer(accounts[1], 100, {from: accounts[2]});
        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await checkProfits([11.5, 4.75, 5.75], 1, "transfer_1");

        await sharesToken.mint(admin, 200);
        await sharesToken.mint(accounts[1], 300);
        await checkProfits([11.5, 4.75, 5.75], 1, "mint_2");

        // balance: [6 6 3] -> [1.2 1.2 0.6]
        await fiatToken.transfer(sharesToken.address, 3 * decimals, {from: admin});
        await checkProfits([12.7, 5.95, 6.35], 1, "mint_3");

        await sharesToken.withdrawProfit(2 * decimals, 1, {from: accounts[1]});
        await sharesToken.withdrawProfit(3 * decimals, 1, {from: accounts[2]});
        await sharesToken.mint(accounts[3], 500);
        await sharesToken.transfer(accounts[3], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 200, {from: accounts[2]});
        await sharesToken.transfer(accounts[3], 300, {from: admin});
        await checkProfits([12.7, 3.95, 3.35, 0], 1, "withdraw");

        // balance [5 5 1 9] -> [2.5 2.5 0.5 4.5]
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await checkProfits([15.2, 6.45, 3.85, 4.5], 1, "mint_4");
    });
});

