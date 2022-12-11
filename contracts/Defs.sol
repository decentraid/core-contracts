/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract Defs {

    bytes32  TLD_TYPE_DOMAIN;
    bytes32  TLD_TYPE_SOULBOUND;

    enum SortOrder {
        ASCENDING_ORDER,
        DESCENDING_ORDER
    }

    enum NodeType  {
        DOMAIN,
        SUBDOMAIN,
        TLD
    }

    struct FeedInfo {
        uint256  rate;
        uint     decimals; 
    }

    struct PaymentTokenDef {
        address tokenAddress;
        address priceFeedContract; // chainlink price feed
        bool    enabled;
        uint256 addedOn;
        uint256 updatedOn; 
    }

    struct PaymentTokenInfo {
        string          name;
        string          symbol;
        uint            decimals;
        PaymentTokenDef paymentToken;
        FeedInfo        feedInfo;
    }

    // by character length
    struct DomainPrices {
        uint256  _1char;
        uint256  _2chars;
        uint256  _3chars;
        uint256  _4chars;
        uint256  _5pchars;
    }

    struct TLDInfo {
        uint256         id;
        string          label;
        bytes32         tldType;
        bytes32         namehash;
        string          webUrl;
        string          metadataUri;
        uint            minLen;
        uint            maxLen;
        DomainPrices    prices;     
        uint256         createdAt;
        uint256         updatedAt;
    }

    struct Node {
        string      label;
        bytes32     namehash;
        bytes32     primaryNode;
        bytes32     parentNode; 
        NodeType    nodeType;
        uint256     tokenId;
        uint256     tldId;
        SvgProps    svgImageProps;
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

    struct RegistrarNodeInfo {
        address   assetAddress;
        uint256   tokenId;
        bytes32   node;
        bytes32   tld;
        address   userAddress;
    }

    struct SvgProps {
        string cords;
        string[][] gcolors;
    }
    

    struct PriceInfoDef {
        uint256 price;
        address tokenAddress; 
        string  name;
        string  symbol; 
        uint256 decimals;
    }


}