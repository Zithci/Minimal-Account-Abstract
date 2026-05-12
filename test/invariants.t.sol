// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {DeployMinimalAccount} from "../script/DeployMinimalAccount.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Handler} from "./Handler.t.sol";

contract Invariants is StdInvariant, Test {
    Handler public handler;
    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;
    address public owner;

    function setUp() public {
        DeployMinimalAccount deployer = new DeployMinimalAccount();
        (minimalAccount, helperConfig) = deployer.run();
        (, owner) = helperConfig.activeNetworkConfig();
        
        // Initializing the handler
        handler = new Handler(minimalAccount, owner);

        // Change the target, now Foundry will spam the handler 
        targetContract(address(handler));
    }

    function invariant_testEntryPointNeverChanges() public view {
        (address entryPoint, ) = helperConfig.activeNetworkConfig();
        address actualEntryPoint = minimalAccount.getEntryPoint();
        assertEq(actualEntryPoint, entryPoint);
    }
}
