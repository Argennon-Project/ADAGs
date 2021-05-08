// SPDX-License-Identifier: GPL-3.0-or-later

exports.NOT_AUTHORIZED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert " +
    "sender not authorized -- Reason given: sender not authorized.";
exports.MINT_ALLOWANCE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert amount " +
    "exceeds allowance -- Reason given: amount exceeds allowance.";
exports.EXCEEDS_MAX_SUPPLY_ERROR = "Error: Returned error: VM Exception while processing transaction: revert " +
    "totalSupply exceeds limit -- Reason given: totalSupply exceeds limit.";
exports.LOCKED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert not enough " +
    "non-locked tokens -- Reason given: not enough non-locked tokens.";
exports.LOCK_UPDATE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert locks can only " +
    "be extended -- Reason given: locks can only be extended.";
exports.BAD_INPUT_ERROR = "Error: Returned error: VM Exception while processing transaction: revert bad inputs " +
    "-- Reason given: bad inputs.";
exports.LOW_BALANCE_ERROR = "Error: Returned error: VM Exception while processing transaction: revert profit balance " +
    "is not enough -- Reason given: profit balance is not enough.";
exports.WITHDRAW_NOT_ALLOWED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert " +
    "withdrawal not allowed -- Reason given: withdrawal not allowed.";
exports.ALREADY_REGISTERED_ERROR = "Error: Returned error: VM Exception while processing transaction: revert already " +
    "registered -- Reason given: already registered.";

exports.expectError = async function (promise, error) {
    let passed = false;
    try {
        await promise;
        passed = true;
    } catch (e) {
        assert.equal(e.toString(), error,"Invalid error");
    }
    if (passed) throw(`No errors given, While expecting: ${error}`);
}
