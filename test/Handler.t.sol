// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";

contract Handler is Test {
    MinimalAccount public minimalAccount;
    address public owner;
    uint256 public timesExecuteCalled;

    constructor(MinimalAccount _minimalAccount, address _owner) {
        minimalAccount = _minimalAccount;
        owner = _owner;
    }

    function deposit(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        vm.deal(address(minimalAccount), amount);
    }

    function execute(uint256 amount) public {
        if (address(minimalAccount).balance == 0) {
            return;
        }    
        amount = bound(amount, 1, address(minimalAccount).balance);
        vm.prank(owner);
        minimalAccount.execute(makeAddr("any-target"), amount, "");
        timesExecuteCalled++;
    }        
}
