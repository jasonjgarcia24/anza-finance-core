const { ethers } = require("ethers");
const config = require('../anza/src/config.json');
require('dotenv').config();

const compiled_AnzaToken = require('../anza/src/artifacts/AnzaToken.sol/AnzaToken.json');
const compiled_LoanContract = require('../anza/src/artifacts/LoanContract.sol/LoanContract.json');
const compiled_LoanTreasurey = require('../anza/src/artifacts/LoanTreasurey.sol/LoanTreasurey.json');
const compiled_LoanCollateralVault = require('../anza/src/artifacts/CollateralVault.sol/CollateralVault.json');
const compile_LibLoanContractInterest = require('../anza/src/artifacts/LibLoanContract.sol/LibLoanContractInterest.json');
const compile_LibLoanContractRoles = require('../anza/src/artifacts/LibLoanContractConstants.sol/LibLoanContractRoles.json');
const { assert } = require('chai');
