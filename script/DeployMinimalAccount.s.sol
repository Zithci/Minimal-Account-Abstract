// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "../src/MinimalAccount.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMinimalAccount is Script {
    function run() external returns (MinimalAccount, HelperConfig) {
        // 1. Ambil Config
        HelperConfig helperConfig = new HelperConfig();
        (address entryPoint, address owner) = helperConfig.activeNetworkConfig();

        // 2. Deploy
        vm.startBroadcast();
        MinimalAccount minimalAccount = new MinimalAccount(entryPoint);

        // Pindahkan ownership ke alamat yang ada di config (atau msg.sender)
        minimalAccount.transferOwnership(owner);
        vm.stopBroadcast();

        return (minimalAccount, helperConfig);
    }
}
