// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/RWAPoolVault.sol";

struct VaultConfig {
    string name;
    string symbol;
    uint256 mintRatioNumerator;
    uint256 mintRatioDenominator;
}

contract DeployVault is Script {
    function run() external {
        VaultConfig[] memory vaults = new VaultConfig[](3);

        vaults[0] = VaultConfig("Diversified Digital Gold", "rGold", 998, 1000);
        vaults[1] = VaultConfig("Institutional Liquidity", "rInst", 980, 1000);
        vaults[2] = VaultConfig("Gold Treasury Yield", "rYield", 995, 1000);

        // Retrieve the private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Get USDC address from environment variable
        address usdcAddress = vm.envAddress("USDC_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the vault contracts with msg.sender as the initial owner and USDC address
        for (uint256 i = 0; i < vaults.length; i++) {
            VaultConfig memory config = vaults[i];
            RWAPoolVault vault = new RWAPoolVault(
                usdcAddress, config.name, config.symbol, config.mintRatioNumerator, config.mintRatioDenominator
            );

            // Log the deployed contract address
            console.log("Vault deployed to:", address(vault), "with symbol:", config.symbol);
        }

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
