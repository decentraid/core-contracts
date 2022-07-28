/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "./Defs.sol";
import "./interface/IBNS.sol";

contract DataStore is Defs {

    // self instance 
    IBNS immutable __INSTANCE = IBNS(address(this));

    // icann standard
    uint constant public MAX_LABEL_LENGTH = 63;

    // max subdomain depth
    //uint constant public MAX_SUBDOMAIN_DEPTH = 3;

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