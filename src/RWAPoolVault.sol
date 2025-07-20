// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract RWAPoolVault is ERC20, Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public immutable USDC;
    uint256 public constant MINT_RATIO_NUMERATOR = 998;
    uint256 public constant MINT_RATIO_DENOMINATOR = 1000;

    // Admin management
    mapping(address => bool) public adminAddresses;

    // Events
    event USDCReceived(address indexed from, uint256 usdcAmount);
    event VaultTokenMinted(
        address indexed to,
        uint256 amount,
        uint256 usdcAmount
    );
    event USDCWithdrawn(address indexed to, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);

    // Pause and UnPause Function
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Modifiers
    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner() || adminAddresses[msg.sender],
            "Not owner or admin"
        );
        _;
    }

    constructor(
        address usdcAddress,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable() {
        require(usdcAddress != address(0), "Invalid USDC address");

        _transferOwnership(msg.sender);

        USDC = IERC20(usdcAddress);
    }

    // Minting function
    function mint(
        address to,
        uint256 amount
    ) public nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(to != address(0), "Cannot mint to zero address");

        uint256 usdcAmount = Math.mulDiv(
            amount,
            MINT_RATIO_DENOMINATOR * 1e6,
            MINT_RATIO_NUMERATOR * 1e18,
            Math.Rounding.Up
        );

        require(usdcAmount > 0, "USDC amount too small");
        USDC.safeTransferFrom(msg.sender, address(this), usdcAmount);
        _mint(to, amount);

        emit USDCReceived(msg.sender, usdcAmount);
        emit VaultTokenMinted(to, amount, usdcAmount);
    }

    // Admin management functions
    function addAdminAddress(address admin) public onlyOwner {
        require(admin != address(0), "Cannot add zero address as admin");
        require(!adminAddresses[admin], "Address already admin");
        adminAddresses[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdminAddress(address admin) public onlyOwner {
        require(adminAddresses[admin], "Address is not admin");
        adminAddresses[admin] = false;
        emit AdminRemoved(admin);
    }

    // Withdrawal function
    function withdrawUSDC(
        uint256 amount
    ) public onlyOwnerOrAdmin nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        uint256 contractBalance = USDC.balanceOf(address(this));
        require(contractBalance >= amount, "Insufficient USDC balance");

        USDC.safeTransfer(msg.sender, amount);
        emit USDCWithdrawn(msg.sender, amount);
    }

    // View functions for transparency
    function calculateUsdcRequired(
        uint256 vaultTokenAmount
    ) public pure returns (uint256) {
        return
            Math.mulDiv(
                vaultTokenAmount,
                MINT_RATIO_DENOMINATOR * 1e6,
                MINT_RATIO_NUMERATOR * 1e18,
                Math.Rounding.Up
            );
    }

    function getContractUsdcBalance() external view returns (uint256) {
        return USDC.balanceOf(address(this));
    }

    function getExchangeRate()
        external
        pure
        returns (uint256 usdcPer1000vaultToken)
    {
        // Returns USDC (6 decimals) needed for 1000 vaultToken tokens
        return calculateUsdcRequired(1000 * 1e18);
    }

    function isAdmin(address account) external view returns (bool) {
        return adminAddresses[account];
    }
}
