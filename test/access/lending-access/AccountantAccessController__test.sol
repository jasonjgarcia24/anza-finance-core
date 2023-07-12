// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console} from "forge-std/console.sol";

import {_ADMIN_, _LOAN_CONTRACT_, _COLLATERAL_VAULT_} from "@lending-constants/LoanContractRoles.sol";

import {AccountantAccessController} from "@lending-access/AccountantAccessController.sol";
import {IDebtBook} from "@lending-databases/interfaces/IDebtBook.sol";
import {IDebtTerms} from "@lending-databases/interfaces/IDebtTerms.sol";
import {ILoanManager} from "@services-interfaces/ILoanManager.sol";
import {ILoanCodec} from "@services-interfaces/ILoanCodec.sol";
import {ICollateralVault} from "@services-interfaces/ICollateralVault.sol";

import {Setup} from "@test-base/Setup__test.sol";

contract AccountantAccessContollerHarness is AccountantAccessController {
    function exposed__loanContract() public view returns (IDebtBook) {
        return _loanContract;
    }

    function exposed__loanDebtTerms() public view returns (IDebtTerms) {
        return _loanDebtTerms;
    }

    function exposed__loanManager() public view returns (ILoanManager) {
        return _loanManager;
    }

    function exposed__loanCodec() public view returns (ILoanCodec) {
        return _loanCodec;
    }

    function exposed__collateralVault() public view returns (ICollateralVault) {
        return _collateralVault;
    }

    function exposed__grantRole(bytes32 _role, address _account) public {
        _grantRole(_role, _account);
    }

    /* Abstract functions */
    /* ^^^^^^^^^^^^^^^^^^ */
}

abstract contract AccountantAccessControllerInit is Setup {
    AccountantAccessContollerHarness public accountantAccessControllerHarness;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);
        accountantAccessControllerHarness = new AccountantAccessContollerHarness();
        vm.stopPrank();
    }
}

contract AccountantAccessControllerUnitTest is AccountantAccessControllerInit {
    function _testLoanContract(address _account) internal {
        assertTrue(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _account
            ),
            "0 :: _testLoanContract :: _loanContractAddress should have _LOAN_CONTRACT_ role."
        );

        assertEq(
            address(accountantAccessControllerHarness.exposed__loanContract()),
            _account,
            "1 :: _testLoanContract :: _loanContract does not match expected address"
        );

        assertEq(
            address(accountantAccessControllerHarness.exposed__loanDebtTerms()),
            _account,
            "2 :: _testLoanContract :: _loanDebtTerms does not match expected address."
        );

        assertEq(
            address(accountantAccessControllerHarness.exposed__loanManager()),
            _account,
            "3 :: _testLoanContract :: _loanManager does not match expected address."
        );

        assertEq(
            address(accountantAccessControllerHarness.exposed__loanCodec()),
            _account,
            "4 :: _testLoanContract :: _loanCodec does not match expected address."
        );

        assertEq(
            accountantAccessControllerHarness.loanContract(),
            _account,
            "5 :: LoanContract address mismatch."
        );
    }

    function _testCollateralVault(address _account) internal {
        assertTrue(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _account
            ),
            "0 :: _testCollateralVault :: _loanContractAddress should have _COLLATERAL_VAULT_ role."
        );

        assertEq(
            address(
                accountantAccessControllerHarness.exposed__collateralVault()
            ),
            _account,
            "1 :: _testCollateralVault :: _loanContract does not match expected address"
        );

        assertEq(
            accountantAccessControllerHarness.collateralVault(),
            _account,
            "2 :: CollateralVault address mismatch."
        );
    }

    /* ----------- AccountantAccessController._grantRole() ----------- */
    /**
     * Fuzz test for setting the LoanContract address without AccessControl.
     *
     * @param _loanContractAddress The address of the LoanContract contract.
     * @param _altLoanContractAddress The alternate address of the LoanContract
     * contract.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testAccountantAccessController__GrantRole_Fuzz_SetLoanContract(
        address _loanContractAddress,
        address _altLoanContractAddress
    ) public {
        vm.assume(_loanContractAddress != _altLoanContractAddress);

        // Set the LoanContract address.
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContractAddress
            ),
            "0 :: _loanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        assertEq(
            accountantAccessControllerHarness.loanContract(),
            address(0),
            "1 :: LoanContract address mismatch."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _LOAN_CONTRACT_,
            _loanContractAddress
        );

        _testLoanContract(_loanContractAddress);

        // Alt account setting
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _altLoanContractAddress
            ),
            "2 :: _altLoanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _LOAN_CONTRACT_,
            _altLoanContractAddress
        );

        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContractAddress
            ),
            "3 :: _loanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        _testLoanContract(_altLoanContractAddress);
    }

    /* ----------- AccountantAccessController._grantRole() ----------- */
    /**
     * Fuzz test for setting the CollateralVault address without AccessControl.
     *
     * @param _collateralVaultAddress The address of the CollateralVault contract.
     * @param _altCollateralVaultAddress The alternate address of the CollateralVault
     * contract.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testAccountantAccessController__GrantRole_Fuzz_SetCollateralVault(
        address _collateralVaultAddress,
        address _altCollateralVaultAddress
    ) public {
        vm.assume(_collateralVaultAddress != _altCollateralVaultAddress);

        // Set the CollateralVault address.
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _collateralVaultAddress
            ),
            "0 :: _collateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        assertEq(
            accountantAccessControllerHarness.collateralVault(),
            address(0),
            "1 :: CollateralVault address mismatch."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _COLLATERAL_VAULT_,
            _collateralVaultAddress
        );

        _testCollateralVault(_collateralVaultAddress);

        // Alt account setting
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _altCollateralVaultAddress
            ),
            "2 :: _altCollateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _COLLATERAL_VAULT_,
            _altCollateralVaultAddress
        );

        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _collateralVaultAddress
            ),
            "3 :: _collateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        _testCollateralVault(_altCollateralVaultAddress);
    }

    /* ----------- AccountantAccessController.grantRole() ----------- */
    /**
     * Fuzz test for setting the LoanContract address with AccessControl.
     *
     * @param _loanContractAddress The address of the LoanContract contract.
     * @param _altLoanContractAddress The alternate address of the LoanContract
     * contract.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testAccountantAccessController_GrantRole_Fuzz_SetLoanContract(
        address _loanContractAddress,
        address _altLoanContractAddress
    ) public {
        vm.assume(_loanContractAddress != _altLoanContractAddress);

        // Set the LoanContract address.
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContractAddress
            ),
            "0 :: _loanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        assertEq(
            accountantAccessControllerHarness.loanContract(),
            address(0),
            "1 :: LoanContract address mismatch."
        );

        vm.expectRevert(
            abi.encodePacked(getAccessControlFailMsg(_ADMIN_, address(this)))
        );
        accountantAccessControllerHarness.grantRole(
            _LOAN_CONTRACT_,
            _loanContractAddress
        );

        vm.startPrank(admin);
        accountantAccessControllerHarness.grantRole(
            _LOAN_CONTRACT_,
            _loanContractAddress
        );
        vm.stopPrank();

        _testLoanContract(_loanContractAddress);

        // Alt account setting
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _altLoanContractAddress
            ),
            "2 :: _altLoanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _LOAN_CONTRACT_,
            _altLoanContractAddress
        );

        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _LOAN_CONTRACT_,
                _loanContractAddress
            ),
            "3 :: _loanContractAddress should not have _LOAN_CONTRACT_ role."
        );

        _testLoanContract(_altLoanContractAddress);
    }

    /* ----------- AccountantAccessController.grantRole() ----------- */
    /**
     * Fuzz test for setting the CollateralVault address with AccessControl.
     *
     * @param _collateralVaultAddress The address of the CollateralVault contract.
     * @param _altCollateralVaultAddress The alternate address of the CollateralVault
     * contract.
     *
     * @dev Full pass if the address is set correctly.
     */
    function testAccountantAccessController_GrantRole_Fuzz_SetCollateralVault(
        address _collateralVaultAddress,
        address _altCollateralVaultAddress
    ) public {
        vm.assume(_collateralVaultAddress != _altCollateralVaultAddress);

        // Set the CollateralVault address.
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _collateralVaultAddress
            ),
            "0 :: _collateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        assertEq(
            accountantAccessControllerHarness.collateralVault(),
            address(0),
            "1 :: CollateralVault address mismatch."
        );

        vm.expectRevert(
            abi.encodePacked(getAccessControlFailMsg(_ADMIN_, address(this)))
        );
        accountantAccessControllerHarness.grantRole(
            _COLLATERAL_VAULT_,
            _collateralVaultAddress
        );

        vm.startPrank(admin);
        accountantAccessControllerHarness.grantRole(
            _COLLATERAL_VAULT_,
            _collateralVaultAddress
        );
        vm.stopPrank();

        _testCollateralVault(_collateralVaultAddress);

        // Alt account setting
        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _altCollateralVaultAddress
            ),
            "2 :: _altCollateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        accountantAccessControllerHarness.exposed__grantRole(
            _COLLATERAL_VAULT_,
            _altCollateralVaultAddress
        );

        assertFalse(
            accountantAccessControllerHarness.hasRole(
                _COLLATERAL_VAULT_,
                _collateralVaultAddress
            ),
            "3 :: _collateralVaultAddress should not have _COLLATERAL_VAULT_ role."
        );

        _testCollateralVault(_altCollateralVaultAddress);
    }
}
