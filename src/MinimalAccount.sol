// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAccount} from "account-abstraction/interfaces/IAccount.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/core/Helpers.sol";

contract MinimalAccount is IAccount, Ownable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error MinimalAccount__NotEntryPoint();
    error MinimalAccount__NotEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes result);

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    address private immutable i_entryPoint;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireFromEntryPoint() {
        if (msg.sender != i_entryPoint) {
            revert MinimalAccount__NotEntryPoint();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = entryPoint;
    }

    /**
     * @notice Allows the wallet to execute transactions
     * @dev This can be called by the EntryPoint or the Owner directly
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        // STEP 1: Security check! Who should be able to call this?
        // Hint: Only EntryPoint or Owner
        if(msg.sender != owner() && msg.sender !=  i_entryPoint){
            revert MinimalAccount__NotEntryPointOrOwner() ;
        }
        
        // STEP 2: Execute the call to the destination
        // Hint: Use (bool success, bytes memory result) = dest.call{value: value}(func);
        (bool success, bytes memory  result) = dest.call{value : value }(func);

        // STEP 3: Handle the failure case
        if(!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    /**
     * @notice EntryPoint calls this to validate the transaction
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external requireFromEntryPoint returns (uint256 validationData) {
        // 1. Validate the signature
        validationData = _validateSignature(userOp, userOpHash);
        
        // 2. Pay for the gas (Entry Point expects this)
        _payPrefund(missingAccountFunds);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal helper to check if the owner signed the userOp
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal view returns (uint256 validationData) {
        // 1. Convert userOpHash to EthSignedMessageHash
        bytes32 ethSignedHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);

        // 2. Recover signer using ECDSA.recover
        address actualSigner = ECDSA.recover(ethSignedHash, userOp.signature);
        
        // 3. Return SIG_VALIDATION_SUCCESS or SIG_VALIDATION_FAILED
        if(actualSigner != owner()){
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    /**
     * @notice Internal helper to pay for prefund
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds > 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds}("");
            require(success, "Prefund failed");
        }
    }

    receive() external payable {}
    
    /*//////////////////////////////////////////////////////////////
                                GETTERS
    /////////////////////////////////////////////////////////////*/
    function getEntryPoint() external view returns (address) {
        return i_entryPoint;
    }
}
