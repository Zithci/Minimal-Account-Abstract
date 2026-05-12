// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {DeployMinimalAccount} from "../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {PackedUserOperation} from "account-abstraction/interfaces/PackedUserOperation.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/core/Helpers.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    
    address public entryPoint;
    address public owner;
    uint256 public ownerKey;

    function setUp() public {
        // Step 1: Panggil script deploy kita
        DeployMinimalAccount deployer = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployer.run();
        
        // Step 2: Ambil config-nya (Biar test sinkron ama script deploy)
        (entryPoint, owner) = helperConfig.activeNetworkConfig();
        
        // Karena di HelperConfig kita pake burner address, 
        // kita butuh key-nya buat ngetest tanda tangan.
        // Kita timpa dikit buat testing biar dapet private key-nya.
        (owner, ownerKey) = makeAddrAndKey("owner");
        vm.prank(minimalAccount.owner());
        minimalAccount.transferOwnership(owner);
    }

    /*//////////////////////////////////////////////////////////////
                           VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testOwnerCanSignAndValidate() public {
        PackedUserOperation memory userOp;
        userOp.sender = address(minimalAccount);
        userOp.nonce = 0;
        
        bytes32 userOpHash = keccak256(abi.encode("test-hash"));
        bytes32 ethSignedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedMessageHash);
        userOp.signature = abi.encodePacked(r, s, v);
        
        vm.prank(entryPoint);
        uint256 validationData = minimalAccount.validateUserOp(userOp, userOpHash, 0);
        
        assertEq(validationData, SIG_VALIDATION_SUCCESS);
    }

    /*//////////////////////////////////////////////////////////////
                             EXECUTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testOwnerCanExecute() public {
        // Setup target kirim ETH
        address dest = makeAddr("destination");
        uint256 value = 1 ether;
        bytes memory data = "";

        // Kasih saldo dulu ke wallet-nya
        vm.deal(address(minimalAccount), value);

        // Aksinya
        vm.prank(owner);
        minimalAccount.execute(dest, value, data);

        // Buktinya
        assertEq(dest.balance, value);
    }

    function testNonOwnerCannotExecute() public {
        address nonOwner = makeAddr("hacker");
        address dest = makeAddr("destination");
        
        vm.prank(nonOwner);
        // Kita expect transaksi ini bakal mental/revert
        vm.expectRevert(MinimalAccount.MinimalAccount__NotEntryPointOrOwner.selector);
        minimalAccount.execute(dest, 1 ether, "");
    }

    function testEntryPointCanExecute() public {
        address dest = makeAddr("destination");
        uint256 value = 1 ether;
        
        vm.deal(address(minimalAccount), value);

        // EntryPoint juga harusnya bisa manggil execute
        vm.prank(entryPoint);
        minimalAccount.execute(dest, value, "");

        assertEq(dest.balance, value);
    }

    function testExecuteFuzz(uint256 value) public {
        // Limit the fuzzing range to a reasonable amount of ETH
        value = bound(value, 1, 1000 ether);
        address dest = makeAddr("fuzz-destination");
        
        vm.deal(address(minimalAccount), value);
        
        vm.prank(owner);
        minimalAccount.execute(dest, value, "");
        
        assertEq(dest.balance, value);
        assertEq(address(minimalAccount).balance, 0);
    }
}
