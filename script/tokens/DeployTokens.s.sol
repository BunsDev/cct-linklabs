// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script, console} from "forge-std/Script.sol";
// for JSON parsing and chain info
import {HelperUtils} from "./utils/HelperUtils.s.sol";
// Network configuration helper
import {HelperConfig} from "./HelperConfig.s.sol"; 
import {BurnMintERC677WithCCIPAdmin} from "../src/BurnMintERC677WithCCIPAdmin.sol";
import {BurnMintERC677} from "@chainlink/contracts-ccip/src/v0.8/shared/token/ERC677/BurnMintERC677.sol";

contract DeployToken is Script {
    function run() external {
        // chainName[id]
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // path/to/config.json
        string memory root = vm.projectRoot();
        string memory configPath = string.concat(root, "/script/config.json");

        // parameters from config.json
        string memory name = HelperUtils.getStringFromJson(vm, configPath, ".BnMToken.name");
        string memory symbol = HelperUtils.getStringFromJson(vm, configPath, ".BnMToken.symbol");
        uint8 decimals = uint8(HelperUtils.getUintFromJson(vm, configPath, ".BnMToken.decimals"));
        uint256 maxSupply = HelperUtils.getUintFromJson(vm, configPath, ".BnMToken.maxSupply");
        bool withGetCCIPAdmin = HelperUtils.getBoolFromJson(vm, configPath, ".BnMToken.withGetCCIPAdmin");
        address ccipAdminAddress = HelperUtils.getAddressFromJson(vm, configPath, ".BnMToken.ccipAdminAddress");

        vm.startBroadcast();

        address deployer = msg.sender;
        address tokenAddress;

        // IF token uses getCCIPAdmin()
        if (withGetCCIPAdmin) {
            // THEN token contract with CCIP admin functionality
            BurnMintERC677WithCCIPAdmin token = new BurnMintERC677WithCCIPAdmin(name, symbol, decimals, maxSupply);

            // ELSE IF CCIP admin address is specified, 
            if (ccipAdminAddress == address(0)) {
                // THEN default to the deployer
                ccipAdminAddress = deployer;
            }
            // THEN set the CCIP admin for the token
            token.setCCIPAdmin(ccipAdminAddress);

            tokenAddress = address(token);
            console.log("Deployed BurnMintERC677WithCCIPAdmin at:", tokenAddress);
        } else {
            // THEN deploy the standard token contract without CCIP admin functionality
            BurnMintERC677 token = new BurnMintERC677(name, symbol, decimals, maxSupply);
            tokenAddress = address(token);
            console.log("Deployed BurnMintERC677 at:", tokenAddress);
        }

        // grants: mint and burn roles to the deployer
        BurnMintERC677(tokenAddress).grantMintAndBurnRoles(deployer);
        console.log("Granted mint and burn roles to:", deployer);

        vm.stopBroadcast();

        // prepares to write the deployed token address to a JSON
        string memory jsonObj = "internal_key";
        string memory key = string(abi.encodePacked("deployedToken_", chainName));
        string memory finalJson = vm.serializeAddress(jsonObj, key, tokenAddress);

        // output file path: deployed token address
        string memory fileName = string(abi.encodePacked("./script/output/deployedToken_", chainName, ".json"));
        console.log("Writing deployed token address to file:", fileName);

        // writes: the JSON containing the deployed token address
        vm.writeJson(finalJson, fileName);
    }
}
