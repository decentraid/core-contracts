// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";


// mock class using ERC20
contract UsdcToken is ERC20, Ownable, ERC20Permit {

    uint256 initialSupply = 1_000_000_000_000_000_000_000_000_000 * (10 ** 18);

    constructor()  ERC20("USDC", "USDC")  ERC20Permit("Kally") {
        _mint( msg.sender, initialSupply );
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

}