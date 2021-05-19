// SPDX-License-Identifier: AGPL-3.0-only

const Errors = require('./errors.js');
const CrowdFunding = artifacts.require("CrowdFunding");
const Argennon = artifacts.require("ArgennonToken");
const FiatToken = artifacts.require("LockableTestToken");

contract("CrowdFunding", (accounts) => {
    const decimals = 1000000;
    let admin = accounts[0];
    let arg, fiat;
    it('checks constructor parameters', async () => {
        fiat = await FiatToken.new(admin , 1000000 * decimals);
        const cf = await CrowdFunding.new(
            admin,
            admin,
            {
                name: "test",
                symbol: "TST",
                redemptionDuration: 3600 * 24 * 6,
                minFiatForActivation: 400,
                totalSupply: 6000000000,
                redemptionRatio: {a: 2, b: 10},
                price: {a: 5000, b: 10000},
                fiatTokenContract: fiat.address,
                originalToken: fiat.address
            }
        );

        const config = await cf.config.call();
        console.log(config.name);
        console.log(config.price.a);
        //assert.equal(config.name.valueOf(), 200, "Amount of lock should be 200");
        //const now = Math.floor(Date.now() / 1000);
    });
});


