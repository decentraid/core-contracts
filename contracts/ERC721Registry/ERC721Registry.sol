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

    event RegisterDomain(uint256 tokenId, bytes32 nameHash);
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    // expiry grace period
    uint256 expiryGracePeriod = 90 days;

    // registry info 
    RegistryInfo  private _registryInfo;

    // domain record registry
    // namehash => domainRecord struct
    mapping(bytes32 => DomainRecord)    private _domainRecords;
    mapping(bytes32 => SubDomainRecord) private _subdomainRecords;

    // reverse uint256 to namehash 
    mapping(uint256 => bytes32) private _tokenIdsNameHashMap;

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
        onlyValidLabel(_tldName)
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
            name:               _tldName,
            hash:               getTLDNameHash(_tldName),
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

    /**
     * @dev if token exists 
     * @param tokenId the token id
     */
    function exists(uint256 tokenId) external view  returns (bool) {
        return _exists(tokenId);
    }


    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId),"BNS#ERC721Registry: UNKNOWN_TOKEN_ID");
        _;
    }


    /**
     * @dev mint a token
     * @param _to the address to mint to
     * @param _label the name of the domain
     * @param _duration how many years the domain should be minted for
     * @param _matadataKeys the meta data keys 
     * @param _metadataValues the metadata values
     */
    function _registerDomain(
        address _to,
        string   calldata _label,
        uint256  _duration,
        string[] calldata _matadataKeys,
        string[] calldata _metadataValues
    ) 
        private 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _domainHash) 
    {
  
        _tokenIdCounter.increment();

        _tokenId = _tokenIdCounter.current();
        
        _mint(_to, _tokenId);

        uint256 minLabelLength = _registryInfo.minDomainLength;

        if(isAdmin(_msgSender())){
            minLabelLength = 1;
        }

        //lets now create our record 
        require(
            bytes(_label).length >= minLabelLength, 
            string(abi.encodePacked("BNS#ERC721Registry: label must exceed ", _registryInfo.minDomainLength, " characters"))
        );
    
        // _registryInfo.maxDomainLength == 0 means no limit
        if(_registryInfo.maxDomainLength > 0) {
            require(
                bytes(_label).length <= _registryInfo.maxDomainLength, 
                string(abi.encodePacked("BNS#ERC721Registry: label must not exceed ", _registryInfo.minDomainLength, " characters"))
            );
        }

        //lets get the domain hash
        _domainHash = nameHash(_label, _registryInfo.hash);


        uint256 _expiry;

        if(_registryInfo.hasExpiry) {

            require(_duration >= 365 days, "BNS#ERC721Registry: minimum duration of 1 year is required");
            _expiry = block.timestamp + _duration;

            bool isDomainExpired = (block.timestamp > _domainRecords[_domainHash].expiry.add(expiryGracePeriod));

            //lets check if we have do not have exiting record domain or expired 
            require(_domainRecords[_domainHash].tokenId == 0 || isDomainExpired, "BNS#ERC721Registry:  Domain is taken");

        }  else {
            // lets check if the domainHash exists
            require(_domainRecords[_domainHash].tokenId == 0, "BNS#ERC721Registry: Domain is taken");
        }

        _domainRecords[_domainHash] = DomainRecord({
            label:              _label,
            hash:               _domainHash,
            registryHash:       _registryInfo.hash,
            tokenId:            _tokenId,
            owner:              _to,
            addressMap:         _to, 
            expiry:             _expiry,
            metadataKeys:       _matadataKeys,
            metadataValues:     _metadataValues,
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });

        // lets create a reverse token id 
        _tokenIdsNameHashMap[_tokenId] = _domainHash;

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

        // lets get the domain record and change the owner to the new owner
        _domainRecords[_tokenIdsNameHashMap[tokenId]].owner = to;

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