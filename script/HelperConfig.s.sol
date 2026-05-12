// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "account-abstraction/core/EntryPoint.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error HelperConfig__InvalidChainId();

    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    NetworkConfig public activeNetworkConfig;

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAIN_ID = 31337;
    address public immutable BURNER_WALLET;

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() {
        BURNER_WALLET = vm.parseAddress("0xaf5b590740e7d226a207d578b2d4638f85e07937");
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == ANVIL_CHAIN_ID) {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            entryPoint: vm.parseAddress("0x5ff137d4b0fdcd49dca30c7cf57e578a026d2789"), account: BURNER_WALLET
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        // Kalo udah pernah di-set, balikin aja
        if (activeNetworkConfig.entryPoint != address(0)) {
            return activeNetworkConfig;
        }

        // Deploy mock EntryPoint di lokal
        vm.startBroadcast();
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        return NetworkConfig({
            entryPoint: address(entryPoint),
            account: vm.parseAddress("0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266") // Default Anvil Address
        });
    }
}
