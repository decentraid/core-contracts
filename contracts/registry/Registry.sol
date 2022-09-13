/** 
* Binance Name Service
* @website github.com/bnsprotocol
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
import "../ContractBase.sol";
import "../resolvers/AddressResolver.sol";
import "../resolvers/TextResolver.sol";
import "hardhat/console.sol";

contract Registry is
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
    event SetPrices();
    event MintDomain(uint256 _tokenId, address _to);
    event MintSubdomain(uint256 _tokenId, address _to);

    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeMathUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    // domain prices data 
    DomainPrices  _domainPrices;

    /**
     * initialize the contract
     */
    function initialize(
        string          memory  _name,
        string          memory  _symbol,
        string          memory  _tldName,
        string          memory  _webHost,
        address[]       memory  _extraMinters,
        address                 _metadataGenAddr,
        address                 _labelValidatorAddr
    )
        public 
        initializer 
    {

        // meta data generator 
        _metadataGenerator = IMetadataGen(_metadataGenAddr);

        // set name label validator addr 
        _nameLabelValidator = ILabelValidator(_labelValidatorAddr);
        
        // validate tld name
        require(_nameLabelValidator.matches(_tldName), "Registry#initialize: INVALID_TLD_NAME");

        
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

    
        _registryInfo = RegistryInfo({
            label:              _tldName,
            namehash:           getTLDNameHash(_tldName),
            assetAddress:       address(this),
            webHost:            _webHost,
            minDomainLength:    2,
            maxDomainLength:    0, // 0 means no limit
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });
        
        
        // lets add more minters 
        for(uint256 i = 0; i < _extraMinters.length; i++) {
            _setupRole(MINTER_ROLE, _extraMinters[i]);
        } //end loop
        
    } //end  initialize


    /**
     * @dev registryInfo sends the registry info
     * @return RegistryInfo
     */
    function getRegistryInfo() 
        public 
        view 
        returns(RegistryInfo memory) 
    {
        return _registryInfo;
    }

    /**
     * @dev if token exists 
     * @param tokenId the token id
     */
    function exists(uint256 tokenId) external view  returns (bool) {
        return _exists(tokenId);
    }


    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId),"Registry#tokenExists: UNKNOWN_TOKEN_ID");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Registry#onlyTokenOwner: NOT_OWNER");
        _;
    }
    
    /**
     * @dev getRecord get the record 
     * @param _node the node to fetch the record
     */
    function getRecord(bytes32 _node)  
        public 
        view 
        returns(Record memory)
    {
        
        //first lets check if the node is a tld, if yes, we send it
        require(_registryInfo.namehash != _node, "Registry#getRecord: REGISTRY_NODE_PROVIDED");

        return _records[_node];
    }

    /**
     * @dev getRecordByTokenId
     */
    function getRecord(uint256 _tokenId)  
        public 
        view 
        tokenExists(_tokenId)
        returns(Record memory)
    {
        return getRecord(_tokenIdToNodeMap[_tokenId]);
    }

    /**
     * override isAuthorized
     */
    function isAuthorised(bytes32 node) internal override view returns(bool){
        
        address owner = ownerOf(_records[node].tokenId);

        if(owner == address(0)) return false;

        if(owner == _msgSender()) return true;

        return this.isApprovedForAll(owner, _msgSender());
    }

    /**
     * @dev setDomainPrices 
     * @param domainPrices_ the domain prices object
     */
    function setPrices(DomainPrices memory domainPrices_) 
        public
        onlyAdmin
    {
        _domainPrices = domainPrices_;
        emit SetPrices();
    }

  
    /**
     * @dev mint a token
     * @param _to the address to mint to
     * @param _label the name of the domain
     * @param _svgImgProps the properties used for generating svg for imageUri
     */
    function _mintDomain(
        address _to,
        string   calldata _label,
        SvgImageProps  memory  _svgImgProps
    ) 
        private 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _node) 
    {

        require( !strMatches(_label, _registryInfo.label), "Registry#_mintDomain: INVALID_LABEL");

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
            string(abi.encodePacked("Registry#_mintDomain: LABEL_MUST_EXCEED_", _registryInfo.minDomainLength, "_CHARACTERS"))
        );


        //lets get the domain hash
        _node = nameHash(_label, _registryInfo.namehash);

        // lets check if the domainHash exists
        require(_records[_node].tokenId == 0, "Registry#_mintDomain: DOMAIN_TAKEN");

        _records[_node] = Record({
            label:              _label,
            namehash:           _node,
            parentNode:         _registryInfo.namehash,
            primaryNode:        _registryInfo.namehash,
            nodeType:           NodeType.DOMAIN,
            tokenId:            _tokenId,
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        }); 


        // lets create a reverse token id 
        _tokenIdToNodeMap[_tokenId] = _node;
        _svgImagesProps[_node] = _svgImgProps;

        emit MintDomain(_tokenId, _to);
    }


    function addDomain(
        address     _to,
        string      calldata _label,
        SvgImageProps  memory  _svgImgProps
    ) 
        public 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _node) 
    {
        return _mintDomain(_to, _label, _svgImgProps);
    }

    /**
     * @dev register a subDomain
     * @param _label the name of the domain
     * @param _parentNode the parent node to create the subdomain from
     */
    function _mintSubdomain(
        string   calldata _label,
        bytes32           _parentNode
    ) 
        private 
        onlyValidLabel(_label)
        onlyAuthorized(_parentNode)
        returns(uint256 _tokenId, bytes32 _node) 
    {

        Record memory _parentRecord = _records[_parentNode];

        require(_parentRecord.createdAt > 0, "Registry#_mintSubdomain: PARENT_NODE_NOT_FOUND");

        bytes32 _primaryNode;
        Record memory _primaryRecord;

        if(_parentRecord.nodeType == NodeType.DOMAIN){
            _primaryNode = _parentRecord.namehash;
             _primaryRecord = _parentRecord;
        } else {
            _primaryNode = _parentRecord.primaryNode;
            _primaryRecord = _records[_primaryNode];
        }

        _tokenIdCounter.increment();

        _tokenId = _tokenIdCounter.current();
        
        address _to = ownerOf(_primaryRecord.tokenId);

        _mint(_to, _tokenId);

        //lets get the subdomain hash
        _node = nameHash(_label, _parentNode);

        _records[_node] = Record({
            label:              _label,
            namehash:           _node,
            parentNode:         _parentNode,
            primaryNode:        _primaryNode,
            nodeType:           NodeType.SUBDOMAIN,
            tokenId:            _tokenId,
            createdAt:          block.timestamp,
            updatedAt:          block.timestamp
        });
    
        // lets create a reverse token id 
        _tokenIdToNodeMap[_tokenId] = _node;

        emit MintSubdomain(_tokenId, _to);
    }

    /**
     * @dev register a subDomain 
     * @param _label the name of the domain
     * @param _parentNode the parent node to create the subdomain from
     */
    function addSubdomain(
        string   calldata _label,
        bytes32           _parentNode
    ) 
        private 
        onlyValidLabel(_label)
        onlyAuthorized(_parentNode)
        returns(uint256 _tokenId, bytes32 _domainHash) 
    {
        return _mintSubdomain(_label, _parentNode);

    }

    /**
     * @dev get domain from token Id 
     * @param _tokenId the token id
     */
    function getDomain(uint256 _tokenId) 
        public 
        view 
        returns(string memory)
    {
        return reverseNode(_tokenIdToNodeMap[_tokenId]);
    }

    /**
     * reverseNode
     */
    function reverseNode(bytes32 _node) 
        public 
        view 
        returns(string memory)
    {

        if(_node ==  _registryInfo.namehash){
            return _registryInfo.label;
        }

        bytes memory _result = abi.encodePacked("");

        while(true){
            
            Record memory _record = getRecord(_node);

            _result =  abi.encodePacked(_result,".");

            if(_record.parentNode == _registryInfo.namehash){
                _result =  abi.encodePacked(_result,_registryInfo.label);
                break;
            } else {
                _node = _record.parentNode;
            }
        }

        return string(_result);
    }


    /**
     * @dev set meta dta generator contract
     */
    function setMetadaGenerator(address _addr)
        public 
        onlyAdmin
    {
        _metadataGenerator = IMetadataGen(_addr);
    }

    /**
     * @dev set name label validator
     * @param _addr the contract address
     */
     function setNameLabelValidator(address _addr)        
        public 
        onlyAdmin
    {
        _nameLabelValidator = ILabelValidator(_addr);
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
        
       bytes32 _node = _tokenIdToNodeMap[tokenId];

       return _metadataGenerator.getTokenURI(reverseNode(_node), _svgImagesProps[_node]);
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
            revert("Registry#_beforeTokenTransfer: SUBDOMAINS_NOT_TRANSFERABLE");
        }   

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
        override( ERC721Upgradeable, IERC721Upgradeable )
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