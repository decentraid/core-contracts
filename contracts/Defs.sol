/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract Defs {

    struct DomainPrices {
        uint256  _1Letter;
        uint256  _2Letters;
        uint256  _3Letters;
        uint256  _4Letters;
        uint256  _5LettersPlus;
    }

    struct RegistryInfo {
        string          tldName;
        bytes32         tldNameHash;
        address         assetAddress;
        string          webHost;
        bool            hasExpiry;
        uint            minDomainLength;
        uint            maxDomainLength;
        DomainPrices    domainPrices;     
        uint256         createdAt;
        uint256         updatedAt;
    }

}