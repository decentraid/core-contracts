/** 
* BNBChain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "../utils/NameUtils.sol";

contract BNSCore is NameUtils {

    // node => registry address 
    mapping(bytes32 => address) private _registry;
    bytes32[] private _registryIndexes;
    
    function getRegistry(string memory _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[getTLDNameHash(_tld)];
    }

    function getRegistry(bytes32 _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[_tld];
    }

    /**
     * ENS resolver 
     */
    function resolver(bytes32 node) public view returns (address) {
        return getRegistry(node);
    }

    /**
     * @dev register a domain
     */
    function registerDomain(
        string memory _label,
        string memory _tld,
        address paymentToken
    )
        public
    {

        

    }


}