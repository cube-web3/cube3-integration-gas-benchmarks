// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/ownable.sol";

import "cube3/contracts/Cube3Integration.sol";

// ERC20 Token without CUBE3 functionality

contract GasBenchmarkToken is ERC20, Ownable {
    mapping(address => uint256) public whitelist;

    uint256 constant MAX_SUPPLY = 1e18 ether;

    event WhitelistAccountUpdated(address indexed account, uint256 amount);

    constructor() payable ERC20("GasBenchmarkToken", "GBT") {
        _mint(address(this), MAX_SUPPLY);
    }

    // ======= Owner functions =======
    function addToWhitelist(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        whitelist[account] += amount;
        emit WhitelistAccountUpdated(account, whitelist[account]);
    }

    // ======= User functions =======
    function whitelistClaimTokens(uint256 amount) external {
        require(whitelist[msg.sender] >= amount, "ERC20: amount exceeds whitelist");
        whitelist[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
    }

    function disperseTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "ERC20: accounts and amounts length mismatch");
        uint256 numAccounts = accounts.length;
        uint256 total;
        for (uint256 i; i < numAccounts;) {
            total += amounts[i];
            unchecked {
                ++i;
            }
        }
        require(total <= balanceOf(msg.sender), "ERC20: insufficient balance");
        _transfer(msg.sender, address(this), total);

        for (uint256 i; i < numAccounts;) {
            _transfer(address(this), accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        return super.transferFrom(from, to, amount);
    }
}

contract GasBenchmarkTokenProtected is ERC20, Ownable, Cube3Integration {
    mapping(address => uint256) public whitelist;

    uint256 constant MAX_SUPPLY = 1e18 ether;

    event WhitelistAccountUpdated(address indexed account, uint256 amount);

    constructor() payable ERC20("GasBenchmarkTokenProtected", "GBTP") Cube3Integration() {
        _mint(address(this), MAX_SUPPLY);
    }

    // ======= Owner functions =======
    function addToWhitelist(address account, uint256 amount) external onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        whitelist[account] += amount;
        emit WhitelistAccountUpdated(account, whitelist[account]);
    }

    // ======= User functions =======
    function whitelistClaimTokens(uint256 amount, bytes calldata cube3Payload) external cube3Protected(cube3Payload) {
        require(whitelist[msg.sender] >= amount, "ERC20: amount exceeds whitelist");
        whitelist[msg.sender] -= amount;
        _transfer(address(this), msg.sender, amount);
    }

    function disperseTokens(address[] memory accounts, uint256[] memory amounts, bytes calldata cube3Payload)
        external
        cube3Protected(cube3Payload)
    {
        require(accounts.length == amounts.length, "ERC20: accounts and amounts length mismatch");
        uint256 numAccounts = accounts.length;
        uint256 total;
        for (uint256 i; i < numAccounts;) {
            total += amounts[i];
            unchecked {
                ++i;
            }
        }
        require(total <= balanceOf(msg.sender), "ERC20: insufficient balance");
        _transfer(msg.sender, address(this), total);

        for (uint256 i; i < numAccounts;) {
            _transfer(address(this), accounts[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function transfer(address to, uint256 amount, bytes calldata cube3Payload)
        public
        cube3Protected(cube3Payload)
        returns (bool)
    {
        return super.transfer(to, amount);
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        (to);
        (amount);
        revert("Use transfer with cube3Payload");
    }

    // Force caller to use the protected version
    function transferFrom(address from, address to, uint256 amount, bytes calldata cube3Payload)
        public
        cube3Protected(cube3Payload)
        returns (bool)
    {
        return super.transferFrom(from, to, amount);
    }

    // force the user to use the protected version
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        (from);
        (to);
        (amount);
        revert("Use transfer with cube3Payload");
    }
}
