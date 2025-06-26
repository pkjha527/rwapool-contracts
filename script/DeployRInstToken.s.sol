// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RInstToken.sol";

contract DeployRInstToken is Script {
    function run() external {
        // Retrieve the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Get USDC address from environment variable
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the token contract with msg.sender as the initial owner and USDC address
        RInstToken token = new RInstToken(usdcAddress);

        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the deployed contract address
        console.log("RInstToken deployed to:", address(token));
    }
}