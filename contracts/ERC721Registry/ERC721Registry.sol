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
import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "contracts/Defs.sol";
import "contracts/roles/Roles.sol";
import "contracts/utils/NameUtils.sol";
import "contracts/ContractBase.sol";
import "contracts/resolvers/AddressResolver.sol";
import "contracts/resolvers/TextResolver.sol";
import "hardhat/console.sol";

contract ERC721Registry is
    ContractBase,
    Roles,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721BurnableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC165StorageUpgradeable,
    NameUtils,
    AddressResolver,
    TextResolver
 {

    event RegisterDomain(uint256 tokenId, bytes32 nameHash);
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    /**
     * initialize the contract
     */
    function initialize(
        string          memory  _name,
        string          memory  _symbol,
        string          memory  _tldName,
        string          memory  _webHost
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

        //init address resolver 
        __AddressResolver_init();

        __TextResolver_init();

        // prices are in usdt
        DomainPrices memory _domainPrices = DomainPrices({
            _1Letter:      5000,
            _2Letters:     3000,
            _3Letters:     500,
            _4Letters:     150,
            _5LettersPlus: 10
        });

        _registryInfo = RegistryInfo({
            label:              _tldName,
            namehash:           getTLDNameHash(_tldName),
            assetAddress:       address(this),
            webHost:            _webHost,
            domainPrices:       _domainPrices,
            minDomainLength:    2,
            maxDomainLength:    0, // 0 means no limit
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

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "BNS#ERC721Registry: NOT_OWNER");
        _;
    }
    

    /**
     * override isAuthorized
     */
    function isAuthorised(bytes32 node) internal override view returns(bool){
        
        if (_records[node].owner == _msgSender()) return true;

        address owner = ownerOf(_records[node].tokenId);

        if(owner == address(0)) return false;

        return this.isApprovedForAll(owner, _msgSender());
    }


    /**
     * @dev mint a token
     * @param _to the address to mint to
     * @param _label the name of the domain
     * @param _matadataKeys the meta data keys 
     * @param _metadataValues the metadata values
     */
    function _registerDomain(
        address _to,
        string   calldata _label,
        string[] calldata _matadataKeys,
        string[] calldata _metadataValues
    ) 
        private 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _node) 
    {
        
        _tokenIdCounter.increment();

        _tokenId = _tokenIdCounter.current();
        
        _mint(_to, _tokenId);

        uint256 minLabelLength = _registryInfo.minDomainLength;

        if(isAdmin(_msgSender())){
            minLabelLength = 1;
        }

        require(_matadataKeys.length  == _metadataValues.length, "BNS#ERC721Registry: unmatched data size for metadata keys & values");

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
        _node = nameHash(_label, _registryInfo.namehash);

        // lets check if the domainHash exists
        require(_records[_node].tokenId == 0, "BNS#ERC721Registry: Domain is taken");

        _records[_node] = Record({
            label:              _label,
            namehash:           _node,
            registryHash:       _registryInfo.namehash,
            tokenId:            _tokenId,
            owner:              _to,
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });


        // lets create a reverse token id 
        _tokenIdToNodeMap[_tokenId] = _node;
    }

    /**
     * @dev register a subDomain
     * @param _to the address to mint to
     * @param _label the name of the domain
     * @param _node the parent node to create the subdomain from
     * @param _matadataKeys the meta data keys 
     * @param _metadataValues the metadata values
     */
    function _registerSubdomain(
        address           _to,
        string   calldata _label,
        bytes32           _node,
        string[] calldata _matadataKeys,
        string[] calldata _metadataValues
    ) 
        private 
        onlyValidLabel(_label)
        onlyAuthorized(_node)
        returns(uint256 _tokenId, bytes32 _domainHash) 
    {

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
        _records[_tokenIdToNodeMap[tokenId]].owner = to;

        delete _reverseAddress[from];

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