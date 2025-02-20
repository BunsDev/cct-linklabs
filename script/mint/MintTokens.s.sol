// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24 <0.9.0;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {BurnMintERC677WithCCIPAdmin} from "../../src/BurnMintERC677WithCCIPAdmin.sol";
import {HelperUtils} from "../utils/HelperUtils.s.sol";

contract MintTokens is Script {
    error InvalidTokenAddress();
    error InvalidMintAmount();

    function run() external {
        // Get the current chain name based on the chain ID
        string memory chainName = HelperUtils.getChainName(block.chainid);

        // Construct paths to the configuration and token JSON files
        string memory root = vm.projectRoot();
        string memory configPath = string.concat(root, "/script/config.json");
        string memory tokenPath = string.concat(root, "/script/output/deployedToken_", chainName, ".json");

        // Extract the token address from the JSON file
        address tokenAddress =
            HelperUtils.getAddressFromJson(vm, tokenPath, string.concat(".deployedToken_", chainName));

        // Read the amount to mint from config.json
        uint256 amount = HelperUtils.getUintFromJson(vm, configPath, ".tokenAmountToMint");

        // Use the sender's address as the receiver of the minted tokens
        address receiverAddress = msg.sender;

        // Replace requires with custom errors
        if (tokenAddress == address(0)) revert InvalidTokenAddress();
        if (amount == 0) revert InvalidMintAmount();

        vm.startBroadcast();

        // Instantiate the token contract at the retrieved address
        BurnMintERC677WithCCIPAdmin tokenContract = BurnMintERC677WithCCIPAdmin(tokenAddress);

        // Mint the specified amount of tokens to the receiver address
        console.log("Minting", amount, "tokens to", receiverAddress);
        tokenContract.mint(receiverAddress, amount);

        console.log("Waiting for confirmations...");

        vm.stopBroadcast();

        console.log("Minted", amount, "tokens to", receiverAddress);
        console.log("Current balance of receiver is", tokenContract.balanceOf(receiverAddress), tokenContract.symbol());
    }
}
