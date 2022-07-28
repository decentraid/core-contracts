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


    // by character length
    struct DomainPrices {
        uint256  one;
        uint256  two;
        uint256  three;
        uint256  four;
        uint256  fivePlus;
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

    /**
     * request auth info
     */
    struct RequestAuthInfo {
        bytes32     authKey; // auth string
        bytes       signature; // auth signature
        uint256     expiry; // expiry
    }

}