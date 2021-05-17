// SPDX-License-Identifier: AGPL-3.0-only

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

    async function checkProfits(profits, sharesToken, sourceIndex, name) {
        for (let i = 0; i < profits.length; i++) {
            assert.equal(
                (await sharesToken.balanceOfProfit.call(accounts[i], sourceIndex)).valueOf(),
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
        await Errors.expectError(
            sharesToken.registerProfitSource(accounts[1], {from: admin}),
            Errors.GENERAL_ERROR
        );

        const fiat1 = await TestToken.new(admin, 100 * decimals);
        const fiat2 = await TestToken.new(admin, 100 * decimals);
        const fiat3 = await TestToken.new(admin, 100 * decimals);
        const fiat4 = await TestToken.new(admin, 100 * decimals);
        await sharesToken.registerProfitSource(fiat1.address, {from: admin});
        await sharesToken.registerProfitSource(fiat2.address, {from: admin});
        await sharesToken.registerProfitSource(fiat3.address, {from: admin});
        await Errors.expectError(
            sharesToken.registerProfitSource(fiat2.address, {from: admin}),
            Errors.ALREADY_REGISTERED_ERROR
        );
        await Errors.expectError(
            sharesToken.finalizeProfitSources({from: accounts[1]}),
            Errors.NOT_AUTHORIZED_ERROR
        );
        await sharesToken.finalizeProfitSources({from: admin});
        await Errors.expectError(
            sharesToken.registerProfitSource(fiat4.address, {from: admin}),
            Errors.FINAL_SOURCES_ERROR
        );

        await Errors.expectError(
            sharesToken.recoverFunds(fiat3.address, 100, {from: admin}),
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
            "Error in final balance of admin"
        );
    });

    it("should handle multiple profit sources", async () => {
        await sharesToken.mint(accounts[1], 200, {from: admin});
        await fiatToken.transfer(sharesToken.address, 12 * decimals, {from: admin});
        await sharesToken.mint(accounts[2], 800, {from: admin});
        await checkProfits([10, 2, 0], sharesToken, 0, "initial");

        const fiat2 = await TestToken.new(admin, 100 * decimals);
        await sharesToken.registerProfitSource(fiat2.address, {from: admin});
        await fiat2.transfer(sharesToken.address, 20 * decimals, {from: admin});
        await sharesToken.transfer(accounts[1], 100, {from: accounts[2]});
        await sharesToken.transfer(accounts[2], 200, {from: accounts[0]});
        await checkProfits([10, 2, 0], sharesToken, 0, "test1_s0");
        await checkProfits([10, 2, 8], sharesToken, 1, "test1_s1");

        await sharesToken.withdrawProfit(2 * decimals, 0, {from: accounts[1]});
        await sharesToken.withdrawProfit(4 * decimals, 1, {from: accounts[2]});
        assert.equal(
            (await fiatToken.balanceOf.call(accounts[1])).valueOf(),
            2 * decimals,
            "Error in source0 withdrawal"
        );
        assert.equal(
            (await fiat2.balanceOf.call(accounts[2])).valueOf(),
            4 * decimals,
            "Error in source1 withdrawal"
        );

        // [800 300 900] -> [1.6 0.6 1.8] , [4 1.5 4.5]
        await fiatToken.transfer(sharesToken.address, 4 * decimals, {from: admin});
        await fiat2.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await sharesToken.transfer(accounts[1], 800, {from: accounts[0]});
        await checkProfits([11.6, 0.6, 1.8], sharesToken, 0, "test2_s0");
        await checkProfits([14, 3.5, 8.5], sharesToken, 1, "test2_s1");

        const fiat3 = await TestToken.new(admin, 100 * decimals);
        await fiat3.transfer(sharesToken.address, 40 * decimals, {from: admin});

        await sharesToken.transfer(accounts[2], 400, {from: accounts[1]});
        // [0 700 1300] - > [0 14 26]
        await sharesToken.registerProfitSource(fiat3.address, {from: admin});
        await checkProfits([11.6, 0.6, 1.8], sharesToken, 0, "test3_s0");
        await checkProfits([14, 3.5, 8.5], sharesToken, 1, "test3_s1");
        await checkProfits([0, 14, 26], sharesToken, 2, "test3_s2");
        await sharesToken.withdrawProfit(25 * decimals, 2, {from: accounts[2]});
        assert.equal(
            (await fiat3.balanceOf.call(accounts[2])).valueOf(),
            25 * decimals,
            "Error in source2 withdrawal for acc2"
        );
        await Errors.expectError(
            sharesToken.withdrawProfit(1.5 * decimals, 2, {from: accounts[2]}),
            Errors.LOW_BALANCE_ERROR
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
        await Errors.expectError(
            sharesToken.withdrawProfit(2n ** 256n - 10n, 1, {from: accounts[1]}),
            Errors.GENERAL_ERROR
        );
        await Errors.expectError(
            sharesToken.withdrawProfit(1, 1, {from: accounts[1]}),
            Errors.GENERAL_ERROR
        );
        assert.equal(
            (await fiatToken.balanceOf.call(accounts[1])).valueOf(),
            9 * decimals,
            "Error in acc1 final balance"
        );
    });

    it("should handle large minting", async () => {
        await fiatToken.transfer(sharesToken.address, 50 * decimals, {from: admin});
        await Errors.expectError(
            sharesToken.mint(admin, 2n ** 220n),
            Errors.GENERAL_ERROR
        );
        await sharesToken.mint(admin, 2n ** 182n);

        await sharesToken.transfer(accounts[1], 100000, {from: admin});
        await sharesToken.transfer(accounts[1], 2n ** 60n, {from: admin});
        await sharesToken.transfer(admin, 2n ** 30n, {from: accounts[1]});
        await Errors.expectError(
            sharesToken.transfer(accounts[1], 10000, {from: admin}),
            Errors.PRECISION_ERROR
        );
        await Errors.expectError(
            sharesToken.transfer(accounts[1], 2n ** 61n, {from: admin}),
            Errors.GENERAL_ERROR
        );
        assert.equal(
            (await sharesToken.balanceOf.call(accounts[1])).valueOf(),
            100000n + 2n ** 60n - 2n ** 30n,
            "Error in acc1 final balance"
        );
    });

    it("should detect overflow", async () => {
        const fiat2 = await TestToken.new(admin, 2n ** 256n - 1n);
        await sharesToken.registerProfitSource(fiat2.address, {from: admin});
        await fiat2.transfer(sharesToken.address, 2n ** 256n - 1n, {from: admin});
        await sharesToken.transfer(accounts[2], 1000, {from: admin});

        await sharesToken.mint(admin, 10n ** 17n);
        await sharesToken.transfer(accounts[1], 10n ** 17n, {from: admin});

        await fiatToken.transfer(sharesToken.address, 15 * decimals, {from: admin});
        await Errors.expectError(
            sharesToken.transfer(admin, 2n ** 250n, {from: accounts[1]}),
            Errors.GENERAL_ERROR
        );
        await Errors.expectError(
            sharesToken.transfer(admin, 2n ** 250n, {from: accounts[2]}),
            Errors.GENERAL_ERROR
        );
    });

    it("should handle underflow", async () => {
        await sharesToken.mint(admin, 50n * 10n ** 15n);
        await fiatToken.transfer(sharesToken.address, decimals, {from: admin});
        await Errors.expectError(
            sharesToken.transfer(accounts[1] , 35000, {from: admin}),
            Errors.PRECISION_ERROR
        );
        await sharesToken.transfer(accounts[1] , 78000, {from: admin})
        await sharesToken.transfer(accounts[1] , 80000, {from: admin});
        await sharesToken.transfer(accounts[1] , 125000, {from: admin});
        await sharesToken.transfer(accounts[1] , 155000, {from: admin});
        await sharesToken.transfer(accounts[1] , 224540, {from: admin});
    });

    it("should handle small amount of profit", async () => {
        await sharesToken.mint(admin, 10n * 10n ** 15n);
        await fiatToken.transfer(sharesToken.address, 100, {from: admin});
        await sharesToken.transfer(accounts[1] , 1, {from: admin});
        await sharesToken.transfer(accounts[1] , 1000000, {from: admin});
        await sharesToken.mint(admin, 10n * 10n ** 15n);
        await sharesToken.transfer(admin , 10, {from: accounts[1]});
    });

    it("distributes profits based on account balances", async () => {
        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});

        await checkProfits([7, 1, 2], sharesToken, 0);

        await sharesToken.withdrawProfit(decimals, 0, {from: accounts[2]});
        await sharesToken.transfer(admin, 50, {from: accounts[2]});
        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});

        await sharesToken.transfer(accounts[1], 300, {from: admin});
        await sharesToken.withdrawProfit(3 * decimals, 0, {from: admin});
        await sharesToken.transfer(accounts[2], 200, {from: admin});

        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});

        await fiatToken.transfer(sharesToken.address, 5 * decimals, {from: admin});

        await checkProfits([5.5, 2.5, 3], sharesToken, 0, "final");

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
        await checkProfits([10, 0], sharesToken, 0, "check1");

        await fiatToken.transfer(sharesToken.address, 6 * decimals, {from: admin});
        await sharesToken.mint(accounts[2], 300);
        await checkProfits([12, 4, 0], sharesToken, 0, "check2");

        await sharesToken.withdrawProfit(4 * decimals, 0, {from: admin});
        await sharesToken.withdrawProfit(2 * decimals, 0, {from: accounts[1]});
        // profits: [8, 2, 0]
        await sharesToken.transfer(accounts[2], 200, {from: admin});
        await sharesToken.transfer(admin, 400, {from: accounts[1]});
        // balances: [700, 600, 500]
        await fiatToken.transfer(sharesToken.address, 9 * decimals, {from: admin});
        // gained profits: [3.5, 3, 2.5]
        await sharesToken.mint(accounts[3], 750);
        await checkProfits([11.5, 5, 2.5, 0], sharesToken, 0, "check3");
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
        await checkProfits([4, 4, 2], sharesToken, 0, "initial_basic");

        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[2], 500, {from: accounts[1]});
        // balance: [3, 0, 7] gained: [1.2, 0, 2.8]
        await checkProfits([5.2, 0, 4.8], sharesToken, 0, "basic");

        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await sharesToken.transfer(accounts[1], 200, {from: accounts[2]});
        await fiatToken.transfer(sharesToken.address, 5 * decimals, {from: admin});
        // balance: [2, 3, 5] gained: [1, 1.5, 2.5]
        await sharesToken.transfer(accounts[1], 200, {from: accounts[2]});
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await checkProfits([6.2, 1.5, 7.3], sharesToken, 0, "initial_advanced");
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 200, {from: accounts[1]});
        await checkProfits([6.2, 1.5, 7.3], sharesToken, 0, "initial_advanced_r");

        await sharesToken.transfer(accounts[2], 100, {from: admin});
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        // gained: (1 - 1.9 / 3) * 0.15 * [3.5, 0.5, 6] = [0.1925, ..]
        await checkProfits([6.3925, 0.9775, 7.63], sharesToken, 0, "advanced_1");

        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await checkProfits([6.3925, 0.9775, 7.63], sharesToken, 0, "advanced_1_r");
        // gained: 0.09775 * [4.5, 0, 5.5] = [0.439875, 0, 0.537625]
        await sharesToken.transfer(admin, 50, {from: accounts[1]});
        await checkProfits([6.832375, 0, 8.167625], sharesToken, 0, "advanced_2");
    });

    it("can handle minting and transferring", async () => {
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
        await checkProfits([4, 3, 1], sharesToken, 1, "initial");

        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 100, {from: accounts[1]});
        await sharesToken.transfer(accounts[1], 50, {from: accounts[2]});
        // balance: [5 1.5 1.5] -> [2.5 0.75 0.75]
        await fiatToken.transfer(sharesToken.address, 4 * decimals, {from: admin});
        await sharesToken.mint(accounts[1], 50);
        await sharesToken.mint(accounts[2], 150);
        await sharesToken.transfer(accounts[2], 100, {from: accounts[1]});
        await checkProfits([6.5, 3.75, 1.75], sharesToken, 1, "mint_1");

        // balance: [5 1 4]
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await sharesToken.transfer(accounts[1], 100, {from: accounts[2]});
        await sharesToken.transfer(accounts[1], 100, {from: admin});
        await checkProfits([11.5, 4.75, 5.75], sharesToken, 1, "transfer_1");

        await sharesToken.mint(admin, 200);
        await sharesToken.mint(accounts[1], 300);
        await checkProfits([11.5, 4.75, 5.75], sharesToken, 1, "mint_2");

        // balance: [6 6 3] -> [1.2 1.2 0.6]
        await fiatToken.transfer(sharesToken.address, 3 * decimals, {from: admin});
        await checkProfits([12.7, 5.95, 6.35], sharesToken, 1, "mint_3");

        await sharesToken.withdrawProfit(2 * decimals, 1, {from: accounts[1]});
        await sharesToken.withdrawProfit(3 * decimals, 1, {from: accounts[2]});
        await sharesToken.mint(accounts[3], 500);
        await sharesToken.transfer(accounts[3], 100, {from: accounts[1]});
        await sharesToken.transfer(admin, 200, {from: accounts[2]});
        await sharesToken.transfer(accounts[3], 300, {from: admin});
        await checkProfits([12.7, 3.95, 3.35, 0], sharesToken, 1, "withdraw");

        // balance [5 5 1 9] -> [2.5 2.5 0.5 4.5]
        await fiatToken.transfer(sharesToken.address, 10 * decimals, {from: admin});
        await checkProfits([15.2, 6.45, 3.85, 4.5], sharesToken, 1, "mint_4");
    });
});

