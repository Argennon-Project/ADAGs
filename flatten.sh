#!/bin/sh
truffle-flattener contracts/ADAGs.sol | sed '/^\s*\/\//d' > ../../GolandProjects/ADAGs/deploy/ADAGs_flat.sol
