// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const TokenSale = artifacts.require("TokenSale");
const Argennon = artifacts.require("ArgennonToken");
const FiatToken = artifacts.require("LockableTestToken");

contract("TokenSale", (accounts) => {
    const decimals = 1000000;
    const admin = accounts[8], owner = accounts[9]
    let arg, fiat, cf;
    let normalConfig;

    beforeEach(async () => {
        fiat = await FiatToken.new(admin, decimals * decimals);
        arg = await Argennon.new(admin, owner);

        normalConfig = {
            name: "test ICO",
            symbol: "TST_ICO",
            redemptionDuration: 3600 * 24 * 15,
            minFiatForActivation: 1000 * decimals,
            totalSupply: 5e14,
            redemptionRatio: {a: 80, b: 100},
            price: {a: 1, b: 10000},
            fiatTokenContract: fiat.address,
            originalToken: arg.address
        };
        cf = await TokenSale.new(admin, arg.address, normalConfig);
        await arg.increaseMintingAllowance(cf.address, normalConfig.totalSupply, {from: owner});

        await fiat.transfer(accounts[0], 1000 * decimals, {from: admin});
        await fiat.transfer(accounts[1], 1000 * decimals, {from: admin});
        await fiat.transfer(accounts[2], 20000 * decimals, {from: admin});
        await fiat.transfer(accounts[3], 20000 * decimals, {from: admin});
    });

    it("enables users to buy ico tokens", async () => {
        await fiat.approve(cf.address, 300 * decimals, {from: accounts[0]});
        await Verifier.expectError(
            cf.buy(4 * decimals * decimals, {from: accounts[0]}),
            Verifier.ERC20.ALLOWANCE_ERROR
        );
        await fiat.approve(cf.address, 400 * decimals, {from: accounts[0]});
        await cf.buy(4 * decimals * decimals, {from: accounts[0]});
        assert.equal(
            (await cf.balanceOf.call(accounts[0])).valueOf(),
            4 * decimals * decimals,
            "error in getting ico tokens"
        );
        assert.equal(
            (await fiat.balanceOf.call(cf.address)).valueOf(),
            400 * decimals,
            "error in cf fiat balance"
        );

        // check arithmetic errors
        await fiat.approve(cf.address, 1000 * decimals, {from: accounts[0]});
        await Verifier.expectError(
            cf.buy(333333333333, {from: accounts[0]}),
            Verifier.PRECISION_ERROR
        );
        await cf.buy(1333333333333, {from: accounts[0]});
        assert.equal(
            (await fiat.balanceOf.call(cf.address)).valueOf(),
            400 * decimals + 133333333 + 1,
            "error in cf fiat balance"
        );
        assert.equal(
            (await cf.balanceOf.call(accounts[0])).valueOf(),
            4 * decimals * decimals + 1333333333333,
            "error in acc0 ico token balance"
        );

        await fiat.approve(cf.address, 200 * decimals, {from: accounts[1]});
        await cf.buy(999999999999, {from: accounts[1]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[1])).valueOf(),
            900 * decimals,
            "error in acc1 fiat balance"
        );

        await fiat.approve(cf.address, 2n ** 254n, {from: admin});
        await Verifier.expectError(
            cf.buy(5e14, {from: admin}),
            Verifier.ERC20.TRANSFER_ERROR
        );

        // overflow test
        normalConfig.price = {a: 2000, b: 1000000};
        cf = await TokenSale.new(admin, arg.address, normalConfig);
        await Verifier.expectError(
            cf.buy(2n ** 250n, {from: accounts[0]}),
            Verifier.GENERAL_ERROR
        );
    });

    it("allows withdrawal after redemption end time", async () => {
        normalConfig.redemptionDuration = 10;
        const deployTime = Math.floor(Date.now() / 1000);
        cf = await TokenSale.new(admin, arg.address, normalConfig);
        await arg.increaseMintingAllowance(cf.address, normalConfig.totalSupply, {from: owner});

        await fiat.approve(cf.address, 400 * decimals, {from: accounts[0]});
        await cf.buy(4 * decimals * decimals, {from: accounts[0]});
        assert.equal(
            (await fiat.balanceOf.call(cf.address)).valueOf(),
            400 * decimals,
            "error in payment"
        );
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );

        while (Math.floor(Date.now() / 1000) < deployTime + 12) ;

        await cf.withdraw(400 * decimals);
        assert.equal(
            (await fiat.balanceOf.call(arg.address)).valueOf(),
            400 * decimals,
            "error in withdrawal"
        );
    });

    it("guarantees the configured redemption price after initial phase", async () => {
        await fiat.approve(cf.address, 300 * decimals, {from: accounts[0]});
        await cf.buy(3 * decimals * decimals, {from: accounts[0]});

        await fiat.approve(cf.address, 800 * decimals, {from: accounts[1]});
        await cf.buy(8 * decimals * decimals, {from: accounts[1]});

        await fiat.approve(cf.address, 1500 * decimals, {from: accounts[2]});
        await cf.buy(15 * decimals * decimals, {from: accounts[2]});

        await Verifier.check(fiat.balanceOf.call, [700, 200, 18500], accounts,
            true, "initial fiat balance", decimals);

        // refund at 100%
        await cf.transfer(cf.address, decimals * decimals, {from: accounts[1]});
        await cf.transfer(cf.address, decimals * decimals, {from: accounts[1]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[1])).valueOf(),
            400 * decimals,
            "error in acc1 fiat balance"
        );

        // refund at 87.5%
        await cf.withdraw(300 * decimals);
        assert.equal(
            (await fiat.balanceOf.call(arg.address)).valueOf(),
            300 * decimals,
            "error in beneficiary balance"
        );
        assert.equal(
            (await cf.calculateRefund.call(decimals * decimals)).valueOf(),
            87.5 * decimals,
            "error in beneficiary balance"
        );
        await cf.transfer(cf.address, 3 * decimals * decimals, {from: accounts[2]});
        await cf.transfer(cf.address, decimals * decimals, {from: accounts[2]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[2])).valueOf(),
            (18500 + 350) * decimals,
            "error in acc2 balance"
        );

        await cf.withdraw(150 * decimals);
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );

        // redemption at 80%
        await cf.transfer(accounts[5], 4 * decimals * decimals, {from: accounts[2]});
        await cf.transfer(cf.address, 2 * decimals * decimals, {from: accounts[5]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[5])).valueOf(),
            160 * decimals,
            "error in acc5 balance"
        );
        await cf.transfer(cf.address, decimals * decimals, {from: accounts[5]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[5])).valueOf(),
            240 * decimals,
            "error in acc5 balance"
        );
        assert.equal(
            (await cf.calculateRefund.call(decimals * decimals)).valueOf(),
            80 * decimals,
            "error in redemption price"
        );

        // converting to arg
        await cf.transfer(arg.address, 2 * decimals * decimals, {from: accounts[2]});
        await cf.transfer(arg.address, decimals * decimals, {from: accounts[0]});
        await Verifier.check(arg.balanceOf.call, [decimals, 0, 2 * decimals], accounts,
            true, "arg balances after conversion", decimals);

        // redemption at 17 * 0.8 / 14
        const rp = 17 * 0.8 / 14;
        await cf.transfer(cf.address, 1.5 * decimals * decimals, {from: accounts[0]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[0])).valueOf(),
            Math.floor((700 + 150 * rp) * decimals),
            "error in acc0 refund"
        );
        assert.equal(
            (await cf.calculateRefund.call(decimals * decimals)).valueOf(),
            Math.floor(rp * 100 * decimals),
            "error in redemption price"
        );

        // withdraw 12.5 * (rp - 0.8) * 100
        await cf.withdraw(Math.floor(12.5 * (rp - 0.8) * 100 * decimals + 1));
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );
        assert.equal(
            (await cf.calculateRefund.call(decimals * decimals)).valueOf(),
            Math.floor(80 * decimals),
            "error in redemption price"
        );
    });

    it("allows users to redeem at 100% at the initial phase", async () => {
        await fiat.approve(cf.address, 150 * decimals, {from: accounts[0]});
        await cf.buy(1.5 * decimals * decimals, {from: accounts[0]});

        await fiat.approve(cf.address, 500 * decimals, {from: accounts[1]});
        await cf.buy(2 * decimals * decimals, {from: accounts[1]});

        assert.equal(
            (await fiat.balanceOf.call(cf.address)).valueOf(),
            350 * decimals,
            "error in cf fiat balance"
        );
        await Verifier.check(cf.balanceOf.call, [1.5 * decimals, 2 * decimals], accounts,
            true, "ICO token balance#1", decimals);

        // refund at 100%
        await cf.transfer(cf.address, 100000 * decimals, {from: accounts[0]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[0])).valueOf(),
            860 * decimals,
            "error in refund"
        );
        assert.equal(
            (await cf.balanceOf.call(cf.address)).valueOf(),
            normalConfig.totalSupply - 3400000 * decimals,
            "error in cf ico token balance after refund"
        );

        await cf.transfer(accounts[6], 500000 * decimals, {from: accounts[1]});
        await cf.transfer(cf.address, 500000 * decimals, {from: accounts[6]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[6])).valueOf(),
            50 * decimals,
            "error in refund to acc2"
        );
        assert.equal(
            (await cf.balanceOf.call(cf.address)).valueOf(),
            normalConfig.totalSupply - 2900000 * decimals,
            "error in cf balance"
        );

        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );

        // converting to ARG
        await cf.transfer(arg.address, 300000 * decimals, {from: accounts[0]});
        await cf.transfer(arg.address, 100000 * decimals, {from: accounts[1]});
        await Verifier.check(arg.balanceOf.call, [300000, 100000], accounts,
            true, "ARG token balance#1", decimals);
        assert.equal(
            (await arg.totalSupply.call()).valueOf(),
            5e15 + 400000 * decimals,
            "error in arg total supply"
        );

        // redemption after burning. we should not give extra money.
        await cf.transfer(accounts[7], 1100000 * decimals, {from: accounts[0]});
        await cf.transfer(cf.address, 100000 * decimals, {from: accounts[7]});
        await cf.transfer(cf.address, 600000 * decimals, {from: accounts[7]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[7])).valueOf(),
            70 * decimals,
            "error in acc7 redemption after burning"
        );
        // withdraw after burning
        await cf.withdraw(40 * decimals);
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );

        // redemption after sending money to the cf contract
        await fiat.transfer(cf.address, 100 * decimals, {from: admin});
        assert.equal(
            (await cf.calculateRefund.call(decimals * decimals)).valueOf(),
            100 * decimals,
            "error in redemption price"
        );
        await cf.transfer(cf.address, 400000 * decimals, {from: accounts[7]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[7])).valueOf(),
            110 * decimals,
            "error in acc7 redemption after burning"
        );
        // withdraw after sending money to the cf contract
        await cf.withdraw(100 * decimals);
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.TokenSale.AMOUNT_TOO_HIGH_ERROR
        );
        assert.equal(
            (await fiat.balanceOf.call(arg.address)).valueOf(),
            140 * decimals,
            "error in beneficiary balance"
        );

        await cf.transfer(accounts[5], 300000 * decimals, {from: accounts[1]});
        await cf.transfer(cf.address, 300000 * decimals, {from: accounts[5]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[5])).valueOf(),
            30 * decimals,
            "error in acc5 redemption"
        );
    });

    it("checks constructor parameters", async () => {
        const cf = await TokenSale.new(admin, admin, normalConfig);
        assert.equal(
            (await cf.config.call()).fiatTokenContract.address,
            normalConfig.fiatTokenContract.address,
            "config was not stored correctly"
        );
        assert.equal((await cf.config.call()).price.b, normalConfig.price.b, "error in price");
        assert.equal((await cf.config.call()).redemptionRatio.a, normalConfig.redemptionRatio.a, "error in ratio");

        const invalidDuration = {...normalConfig};
        invalidDuration.redemptionDuration = 3600 * 24 * 2000;
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidDuration),
            Verifier.TokenSale.DURATION_ERROR
        );

        const invalidPrice = {...normalConfig};
        invalidPrice.price = {a: 0, b: 1000};
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidPrice),
            Verifier.TokenSale.ZERO_PRICE_ERROR
        );
        invalidPrice.price = {a: 100, b: 0};
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidPrice),
            Verifier.GENERAL_ERROR
        );

        const invalidRatio = {...normalConfig};
        invalidRatio.redemptionRatio = {a: 101, b: 100};
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidRatio),
            Verifier.TokenSale.REDEMPTION_RATIO_ERROR
        );
        invalidRatio.redemptionRatio = {a: 999, b: 10000};
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidRatio),
            Verifier.TokenSale.REDEMPTION_RATIO_ERROR
        );
        invalidRatio.redemptionRatio = {a: 999, b: 0};
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidRatio),
            Verifier.TokenSale.REDEMPTION_RATIO_ERROR
        );

        const invalidActivation = {...normalConfig};
        invalidActivation.minFiatForActivation = decimals * decimals;
        await Verifier.expectError(
            TokenSale.new(admin, admin, invalidActivation),
            Verifier.TokenSale.MIN_ACTIVATION_ERROR
        );
    });

    it("can handle underflow/overflow", async () => {
        await fiat.approve(cf.address, 1500 * decimals, {from: accounts[2]});
        await cf.buy(15 * decimals * decimals, {from: accounts[2]});

        await Verifier.expectError(
            cf.transfer(cf.address, 2n ** 250n, {from: accounts[2]}),
            Verifier.GENERAL_ERROR
        );
        await Verifier.expectError(
            cf.transfer(arg.address, 2n ** 250n, {from: accounts[2]}),
            Verifier.ERC20.BURN_ERROR
        );

        await Verifier.expectError(
            cf.transfer(cf.address, 99999999999, {from: accounts[2]}),
            Verifier.PRECISION_ERROR
        );
        await cf.transfer(accounts[5], 1999999999999, {from: accounts[2]});
        await cf.transfer(cf.address, 1999999999999, {from: accounts[5]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[5])).valueOf(),
            199999999,
            "error in acc5 redemption"
        );
    });

    it("lets admin recover trapped funds", async () => {
        await arg.mint(cf.address, 100 * decimals, {from: owner});

        await Verifier.expectError(
            cf.recoverFunds(arg.address, 100 * decimals, {from: owner}),
            Verifier.NOT_AUTHORIZED_ERROR
        );

        await Verifier.expectError(
            cf.recoverFunds(cf.address, 100 * decimals, {from: admin}),
            Verifier.WITHDRAW_NOT_ALLOWED_ERROR
        );
        await Verifier.expectError(
            cf.recoverFunds(fiat.address, 100 * decimals, {from: admin}),
            Verifier.WITHDRAW_NOT_ALLOWED_ERROR
        );
        await cf.recoverFunds(arg.address, 50 * decimals, {from: admin});

        await Verifier.expectError(
            cf.setAdmin(accounts[5], {from: accounts[5]}),
            Verifier.NOT_AUTHORIZED_ERROR
        );
        await cf.setAdmin(accounts[5], {from: admin});
        await cf.recoverFunds(arg.address, 50 * decimals, {from: accounts[5]});
        await Verifier.expectError(
            cf.setAdmin(accounts[5], {from: admin}),
            Verifier.NOT_AUTHORIZED_ERROR
        );

        await Verifier.check(arg.balanceOf.call, [50, 50], [admin, accounts[5]],
            true, "final arg balance", decimals);
    });
});


