/** 
* Binance Name Service
* @website github.com/bnsprotocol
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "./ResolverBase.sol";
import "./AddressResolver.sol";
import "./TextResolver.sol";

contract Resolver is 
    Initializable, 
    ERC165StorageUpgradeable,
    ResolverBase,
    AddressResolver,
    TextResolver
{

    function initialize(
        address registryAddr
    ) 
        initializer
        public 
    {

        _registry = IRegistry(registryAddr);

        bytes4 INTERFACE_META_ID = 0x01ffc9a7;

        __ERC165Storage_init_unchained();
        _registerInterface(INTERFACE_META_ID);

        __AddressResolver_init();
        __TextResolver_init();
    }
}