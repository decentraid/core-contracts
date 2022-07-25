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
            _1Letter:      6000,
            _2Letters:     3000,
            _3Letters:     680,
            _4Letters:     200,
            _5LettersPlus: 25
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
     */
    function _registerDomain(
        address _to,
        string   calldata _label
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

        //require(_matadataKeys.length  == _metadataValues.length, "BNS#ERC721Registry: unmatched data size for metadata keys & values");

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
            parentNode:         _registryInfo.namehash,
            primaryNode:        _registryInfo.namehash,
            nodeType:           NodeType.DOMAIN,
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
     * @param _label the name of the domain
     * @param _parentNode the parent node to create the subdomain from
     */
    function _registerSubdomain(
        string   calldata _label,
        bytes32           _parentNode
    ) 
        private 
        onlyValidLabel(_label)
        onlyAuthorized(_parentNode)
        returns(uint256 _tokenId, bytes32 _domainHash) 
    {

        Record memory _parentRecord = _records[_parentNode];

        require(_parentRecord.owner != address(0), "BNS#ERC721Registry#_registerSubdomain: _registerSubdomain parentNode was not found");

        bytes32 _primaryNode;
        Record memory _primaryDomain;

        if(_parentRecord.nodeType == NodeType.DOMAIN){
            _primaryNode = _parentRecord.namehash;
             _primaryDomain = _parentRecord;
        } else {
            _primaryNode = _parentRecord.primaryNode;
            _primaryDomain = _records[_primaryNode];
        }

        _tokenIdCounter.increment();

        _tokenId = _tokenIdCounter.current();

        _mint(_parentRecord.owner, _tokenId);

        //lets get the subdomain hash
        bytes32 _node = nameHash(_label, _parentNode);

        _records[_node] = Record({
            label:              _label,
            namehash:           _node,
            parentNode:         _parentNode,
            primaryNode:        _primaryNode,
            nodeType:           NodeType.SUBDOMAIN,
            tokenId:            _tokenId,
            owner:              address(0),
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });
    
        // lets create a reverse token id 
        _tokenIdToNodeMap[_tokenId] = _node;
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
        
        if(_records[_tokenIdToNodeMap[tokenId]].nodeType == NodeType.SUBDOMAIN){
            revert("BNS#ERC721Registry#_registerSubdomain: Subdomains cannot be transferred");
        }   

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


    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) 
        public 
        view
        override 
        returns 
        (address) 
    {
        
        Record memory _record = _records[_tokenIdToNodeMap[tokenId]];
        
        if(_record.nodeType == NodeType.DOMAIN){
            return super.ownerOf(tokenId);   
        }

        return super.ownerOf(_records[_record.primaryNode].tokenId); 
    }

    //////////////////////////// Overrides Ends  //////////////////////////

    uint256[50] private __gap;
}