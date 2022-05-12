/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "./Defs.sol";

contract DataStore is Defs {

    RegistryInfo                  internal    _registryInfo;
    mapping(bytes32 => Record)    internal     _records;
    mapping(uint256 => bytes32)   internal     _tokenIdToNodeMap;
    mapping(address => bytes32)   internal     _reverseAddress;
    

    // resolver addresses
    // node => address
    mapping(bytes32 => mapping( uint => bytes)) internal _addressRecords;

    // node => key => value
    mapping(bytes32 => mapping(string => string)) internal _textRecords;

}