// SPDX-License-Identifier: AGPL-3.0-only

const Verifier = require('./verifier');
const CrowdFunding = artifacts.require("CrowdFunding");
const Argennon = artifacts.require("ArgennonToken");
const FiatToken = artifacts.require("LockableTestToken");

contract("CrowdFunding", (accounts) => {
    const decimals = 1000000;
    let admin = accounts[8], owner = accounts[9]
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
        cf = await CrowdFunding.new(admin, arg.address, normalConfig);
        await arg.increaseMintingAllowance(cf.address, normalConfig.totalSupply, {from: owner});

        await fiat.transfer(accounts[0], 1000 * decimals, {from: admin});
        await fiat.transfer(accounts[1], 1000 * decimals, {from: admin});
        await fiat.transfer(accounts[2], 20000 * decimals, {from: admin});
        await fiat.transfer(accounts[3], 20000 * decimals, {from: admin});
    });

    it("buy in phase 2", async () => {
        await fiat.approve(cf.address, 300 * decimals, {from: accounts[0]});
        await cf.buy(3 * decimals * decimals, {from: accounts[0]});

        await fiat.approve(cf.address, 800 * decimals, {from: accounts[1]});
        await cf.buy(8 * decimals * decimals, {from: accounts[1]});

        await fiat.approve(cf.address, 1500 * decimals, {from: accounts[2]});
        await cf.buy(15 * decimals * decimals, {from: accounts[2]});

        await Verifier.check(fiat.balanceOf.call, [700, 200, 18500], accounts,
            true, "initial fiat balance", decimals);

        // refund at 100%
        await cf.transfer(cf.address, 2 * decimals * decimals, {from: accounts[1]});
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
        await cf.transfer(cf.address, 4 * decimals * decimals, {from: accounts[2]});
        assert.equal(
            (await fiat.balanceOf.call(accounts[2])).valueOf(),
            (18500 + 350) * decimals,
            "error in acc2 balance"
        );

        await cf.withdraw(150 * decimals);
        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.CrowdFunding.AMOUNT_TOO_HIGH_ERROR
        );
    });

    it("allows users to redeem at 100% at initial phase", async () => {
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
            (await fiat.balanceOf.call(cf.address)).valueOf(),
            290 * decimals,
            "error in cf fiat balance"
        );

        await Verifier.expectError(
            cf.withdraw(1),
            Verifier.CrowdFunding.NOT_YET_ALLOWED_ERROR
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
    });

    it("checks constructor parameters", async () => {
        fiat = await FiatToken.new(admin, 1000000 * decimals);
        arg = fiat;


        const cf = await CrowdFunding.new(
            admin,
            admin,
            normalConfig
        );
        assert.equal(
            (await cf.config.call()).fiatTokenContract.address,
            normalConfig.fiatTokenContract.address,
            "config was not stored correctly"
        );
        assert.equal((await cf.config.call()).price.b, normalConfig.price.b, "error in price");
        assert.equal((await cf.config.call()).redemptionRatio.a, normalConfig.redemptionRatio.a, "error in ratio");

        const invalidDuration = normalConfig;
        invalidDuration.redemptionDuration = 3600 * 24;
        Verifier.expectError(
            CrowdFunding.new(admin, admin, invalidDuration),
            Verifier.CrowdFunding.AMOUNT_TOO_HIGH_ERROR
        );
    });
});


