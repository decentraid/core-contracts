/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract Defs {

    enum NodeType  {
        DOMAIN,
        SUBDOMAIN,
        REGISTRY
    }

    struct DomainPrices {
        uint256  _1Letter;
        uint256  _2Letters;
        uint256  _3Letters;
        uint256  _4Letters;
        uint256  _5LettersPlus;
    }

    struct RegistryInfo {
        string          label;
        bytes32         namehash;
        address         assetAddress;
        string          webHost;
        uint            minDomainLength;
        uint            maxDomainLength;
        DomainPrices    domainPrices;     
        uint256         createdAt;
        uint256         updatedAt;
    }

    struct Record {
        string      label;
        bytes32     namehash;
        bytes32     primaryNode;
        bytes32     parentNode; 
        NodeType    nodeType;
        uint256     tokenId;
        uint256     createdAt;
        uint256     updatedAt;  
    }

}