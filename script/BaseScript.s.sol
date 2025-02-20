// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {console, Script} from "forge-std/Script.sol";

contract BaseScript is Script {
    address public ETH_ROUTER_ADDRESS = vm.envAddress("ETH_ROUTER_ADDRESS");
    address public BASE_ROUTER_ADDRESS = vm.envAddress("BASE_ROUTER_ADDRESS");
    uint256 public constant DEFAULT_REQUIRED_GAS_LIMIT = 1e6;

    uint PRIVATE_KEY = vm.envUint("PRIVATE_KEY");

    // update upon deployment //
    address payable TOKEN_SENDER_ADDRESS = payable(vm.envAddress("TOKEN_SENDER_ADDRESS"));
    address payable TOKEN_RECEIVER_ADDRESS = payable(vm.envAddress("TOKEN_RECEIVER_ADDRESS"));
}