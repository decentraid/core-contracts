/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Roles is Initializable, ContextUpgradeable, AccessControlUpgradeable {

    // Create a new role identifier for the minter role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    function __Roles_init() internal initializer {
        // make caller admin
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    
    /**
     * @dev onlyAdmin modifier
     */
    modifier onlyAdmin {
        require(hasRole(ADMIN_ROLE, _msgSender()), "ONLY_ADMIN_PERMITTED");
        _;
    }

}