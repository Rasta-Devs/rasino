// contracts/KUDIToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockToken is ERC20 {
        

    constructor(uint256 initialSupply, address initialSupplySendAddress)
        public
        ERC20("MockToken", "MOCK")
    {
        _mint(initialSupplySendAddress, initialSupply);
    }
    function mint(address account, uint256 amount)
        external
        returns (bool)
    {
        _mint(account, amount);

        return true;
    }
}