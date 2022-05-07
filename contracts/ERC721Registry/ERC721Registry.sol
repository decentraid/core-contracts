/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "../Defs.sol";
import "../roles/Roles.sol";
import "../utils/NameUtils.sol";
import "hardhat/console.sol";

contract ERC721Registry is
    Initializable,
    ContextUpgradeable,
    Roles,
    ERC721Upgradeable,
    ERC165StorageUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    NameUtils,
    Defs
{
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    // registry info 
    RegistryInfo  private _registryInfo;

    /**
     * initialize the contract
     */
    function initialize(
        string          memory  _name,
        string          memory  _symbol,
        string          memory  _tldName,
        string          memory  _webHost,
        bool                    _hasExpiry
    )
        public 
        initializer 
    {

        // initailize the core components
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC165Storage_init();
        
        // initialize roles
        __Roles_init();

        // prices are in usdt
        DomainPrices memory _domainPrices = DomainPrices({
            _1Letter:      5000,
            _2Letters:     3000,
            _3Letters:     500,
            _4Letters:     150,
            _5LettersPlus: 10
        });

        // lets initiate registry
        _registryInfo = RegistryInfo({
            tldName:            _tldName,
            tldNameHash:        getTLDNameHash(_tldName),
            assetAddress:       address(this),
            webHost:            _webHost,
            domainPrices:       _domainPrices,
            minDomainLength:    2,
            maxDomainLength:    0, // 0 means no limit
            hasExpiry:          _hasExpiry,
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });
    }

    //////////////////////////// Overrides Starts  //////////////////////////

    function _burn(uint256 tokenId)
        internal
        override(
            ERC721Upgradeable, 
            ERC721URIStorageUpgradeable,
            ERC721RoyaltyUpgradeable
        )
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    /**
     * @dev _beforeTokenTransfer 
     */
     function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) 
        internal 
        virtual 
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        virtual 
        override(
            ERC721Upgradeable, 
            ERC721EnumerableUpgradeable, 
            ERC165StorageUpgradeable, 
            ERC721RoyaltyUpgradeable, 
            AccessControlUpgradeable
        ) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    //////////////////////////// Overrides Ends  //////////////////////////

    uint256[50] private __gap;
}