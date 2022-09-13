/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "../ContractBase.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract ResolverBase is Initializable, ContractBase, ERC165StorageUpgradeable {

    bytes4 private constant INTERFACE_META_ID = 0x01ffc9a7;

    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    modifier onlyAuthorized(bytes32 node) {
        require(isAuthorised(node), "ResolverBase: NOT_AUTHORISED");
        _;
    }

    function __ResolverBase_init() internal initializer {
         __ERC165Storage_init_unchained();
        _registerInterface(INTERFACE_META_ID);
    }
}