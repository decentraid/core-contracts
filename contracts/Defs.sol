/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract Defs {

    struct RegistryInfo {
        string      tldName;
        bytes32     tldNameHash;
        address     assetAddress;
        bool        canExpire;
        uint        domainLengthMin;
        uint        domainLengthMax;
        uint256     createdAt;
        uint256     updatedAt;
    }

    struct DomainPrices {
        
    }
}