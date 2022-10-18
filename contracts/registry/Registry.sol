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
//import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "../Defs.sol";
import "../roles/Roles.sol";
import "../utils/NameUtils.sol";
import "../ContractBase.sol";
//import "hardhat/console.sol";

contract Registry is
    ContractBase, 
    Roles,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC165StorageUpgradeable,
    MulticallUpgradeable
 {

    event RegisterDomain(uint256 tokenId, bytes32 nameHash);
    event MintDomain(uint256 tokenId, address to);
    event MintSubdomain(uint256 tokenId, address to);
    event AddTLD(uint256 id);
    event UpdateTLD(uint256 id);
    event SetCollectionUri(string uri);
    event SetController(bytes32 node, address indexed account);


    /**
     * initialize the contract
     */
    function initialize(
        string     memory  _name,
        string     memory  _symbol,
        address[]  memory  _extraMinters,
        address            _metadataGenAddr,
        address            _labelValidatorAddr
    )
        public 
        initializer 
    {

        TLD_TYPE_DOMAIN     = keccak256(abi.encodePacked("TLD_TYPE_DOMAIN"));
        TLD_TYPE_SOULBOUND  = keccak256(abi.encodePacked("TLD_TYPE_SOULBOUND"));

        // meta data generator 
        _metadataGenerator = IMetadataGen(_metadataGenAddr);

        // set name label validator addr 
        _nameLabelValidator = ILabelValidator(_labelValidatorAddr);
        
        // initailize the core components
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ERC165Storage_init();
        
        // initialize roles
        __Roles_init();

        // lets add more minters 
        for(uint256 i = 0; i < _extraMinters.length; i++) {
            _setupRole(MINTER_ROLE, _extraMinters[i]);
        } //end loop
        
    } //end  initialize

    /**
     * @dev add tld
     * @param name the full text tld name
     * @param tld the domain extension in lower case
     * @param webUrl the domain or web url for the tld example: cake.page
     * @param metadataUri the metadata uri for the tld (ipsfs, arweave or ...)
     * @param minLen the minimum domain length 
     * @param maxLen the maximum domain length
     * @param prices the domain prices 
     */
    function addTLD(
        string memory name,
        string memory tld,
        bytes32       tldType,
        string memory webUrl,
        string memory metadataUri,
        uint          minLen,
        uint          maxLen,
        DomainPrices memory prices
    )
        public 
        onlyAdmin
        returns (uint256)
    {
        require(_nameLabelValidator.matches(tld), "Registry: INVALID_TLD_NAME");

        require(tldType == TLD_TYPE_DOMAIN || tldType == TLD_TYPE_SOULBOUND, "Registry: UNKNOWN_TLD_TYPE");
        
        bytes32 tldHash = getTLDNameHash(tld);

        require(_tlds[_tldsIds[tldHash]].createdAt == 0, "Registry: TLD_EXISTS");

        uint256 _id = ++totalTLDs;

        TLDInfo memory tldInfo = TLDInfo(
            _id,
            name,
            tld,      //label
            tldType,
            tldHash, //nameHash
            webUrl,
            metadataUri,
            minLen,
            maxLen,
            prices, 
            block.timestamp,
            block.timestamp
        );

        _tlds[_id] = tldInfo;
        _tldsIds[tldHash] = _id;

        emit AddTLD(_id);

        return _id;
    }

    /**
     * @dev update tld
     * @param id the tld id
     * @param name the full text tld name
     * @param webUrl the domain or web url for the tld example: cake.page
     * @param metadataUri the metadata uri for the tld (ipsfs, arweave or ...)
     * @param minLen the minimum domain length 
     * @param maxLen the maximum domain length
     * @param prices the domain prices 
     */
    function updateTLD(
        uint256 id,
        string memory name,
        string memory webUrl,
        string memory metadataUri,
        uint          minLen,
        uint          maxLen,
        DomainPrices memory prices
    )
        public 
        onlyAdmin
    {   
        
        require(_tlds[id].createdAt > 0, "Registry#updateTLD: TLD_NOT_FOUND");

        _tlds[id].label = name;
        _tlds[id].webUrl = webUrl;
        _tlds[id].metadataUri = metadataUri;
        _tlds[id].minLen = minLen;
        _tlds[id].maxLen = maxLen;
        _tlds[id].prices = prices;
        _tlds[id].updatedAt = block.timestamp;

        emit UpdateTLD(id);
    }

    /**
     * get tld info by hash
     */
    function getTLD(bytes32 node)     
        public 
        view 
        returns(TLDInfo memory) 
    {  
        return _tlds[_tldsIds[node]];
    }

    /**
     * get Tld by id
     */
    function getTLDById(uint256 _id)     
        public 
        view 
        returns(TLDInfo memory) 
    {  
        return _tlds[_id];
    }

    /**
     * @dev get all tlds
     */
    function getTLDs()     
        public 
        view 
        returns(TLDInfo[] memory _tldsArray) 
    {  
        for(uint256 i=0; i <= totalTLDs; i++){
            _tldsArray[i] = _tlds[i];
        }
    }


    /**
     * @dev if token exists 
     * @param tokenId the token id
     */
    function exists(uint256 tokenId) external view  returns (bool) {
        return _exists(tokenId);
    }


    modifier tokenExists(uint256 tokenId) {
        require(_exists(tokenId),"Registry: UNKNOWN_TOKEN_ID");
        _;
    }

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Registry: NOT_OWNER");
        _;
    }
    
    /**
     * @dev getRecord get the record 
     * @param node the node to fetch the record
     */
    function getRecord(bytes32 node)  
        public 
        view 
        returns(Record memory)
    {
        return _records[_recordsNodeToId[node]];
    }

    /**
     * @dev get record by token id
     * @param _tokenId the id to fetch the record
     */
    function getRecordById(uint256 _tokenId)  
        public 
        view 
        returns(Record memory)
    {
        return _records[_tokenId];
    }

    /**
     * @dev get total records by parent
     * @param _node the  node to count the child records
     */
    function getTotalRecordsByParent(bytes32 _node)
        public 
        view 
        returns(uint256)
    {
        return _recordsByParent[_node].length;
    }


    /**
     * @dev get total records by parent
     * @param _node the  node to count the child records
     */
    function getRecordByParentIndex(
        bytes32  _node,
        uint256  _index
    )
        public 
        view 
        returns(Record memory)
    {
        return _records[_recordsByParent[_node][_index]];
    }
   
    /**
     * @dev mint a token
     * @param _to the address to mint to
     * @param _label the name of the domain
     * @param _svgProps the properties used for generating svg for imageUri
     */
    function _mintDomain(
        address             _to,
        string    calldata  _label,
        string    calldata  _tld,
        SvgProps  memory    _svgProps
    ) 
        private 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _node) 
    {

        TLDInfo memory _tldInfo = getTLD(getTLDNameHash(_tld));

        require(_tldInfo.createdAt > 0, "Registry: INVALID_TLD");
        require(!strMatches(_label, _tld), "Registry: INVALID_LABEL");

        _tokenId = ++totalTokenIds;
        
        _mint(_to, _tokenId);

        uint256 minLabelLength = _tldInfo.minLen;

        if(isAdmin(_msgSender())){
            minLabelLength = 1;
        }
        

        //lets now create our record 
        require(
            bytes(_label).length >= minLabelLength, 
            string(abi.encodePacked("Registry#: LABEL_MUST_EXCEED_", _tldInfo.minLen, "_CHARACTERS"))
        );

        //lets get the domain hash
        _node = nameHash(_label, _tldInfo.namehash);

        // lets check if the domainHash exists
        require(getRecord(_node).createdAt == 0, "Registry: DOMAIN_TAKEN");


        _records[_tokenId] = Record(
            _label,
            _node, //namehash
            bytes32(""), //primaryNode
            _tldInfo.namehash, //parentNode
            NodeType.DOMAIN, // nodeType
            _tokenId, //tokenId
            _tldInfo.id, //tldID
            block.timestamp, //createdAt
            block.timestamp //updatedAt
        ); 

        // lets create a reverse token id 
        _recordsNodeToId[_node] = _tokenId;

        // parentNode ids 
        _recordsByParent[_tldInfo.namehash].push(_tokenId);

        _svgImagesProps[_node] = _svgProps;

        emit MintDomain(_tokenId, _to);
    }

    /**
     * mint a domain
     */
    function mintDomain(
        address     _to,
        string      calldata       _label,
        string     calldata        _tld,
        SvgProps    memory         _svgProps
    ) 
        public 
        onlyValidLabel(_label)
        onlyMinter
        returns(uint256 _tokenId, bytes32 _node) 
    {
        return _mintDomain(_to, _label, _tld, _svgProps);
    }

    /**
     * @dev register a subDomain
     * @param _label the name of the domain
     * @param _parentNode the parent node to create the subdomain from
     * @param _svgProps props for svg image 
     */
    function _mintSubdomain(
        string   calldata   _label,
        bytes32             _parentNode,
        SvgProps  memory    _svgProps
    ) 
        private 
        onlyValidLabel(_label)
        returns(uint256 _tokenId, bytes32 _node) 
    {

        Record memory _parentRecord = getRecord(_parentNode);

        require(_parentRecord.createdAt > 0, "Registry#_mintSubdomain: PARENT_NOT_FOUND");

        bytes32 _primaryNode;
        Record memory _primaryRecord;

        if(_parentRecord.nodeType == NodeType.DOMAIN){
            _primaryNode = _parentRecord.namehash;
             _primaryRecord = _parentRecord;
        } else {
            _primaryNode = _parentRecord.primaryNode;
            _primaryRecord = getRecord(_primaryNode);
        }

        _tokenId = ++totalTokenIds;
        
        address _to = ownerOf(_primaryRecord.tokenId);

        _mint(_to, _tokenId);

        //lets get the subdomain hash
        _node = nameHash(_label, _parentNode);

        _records[_tokenId] = Record(
            _label,
            _node, //namehash
            _parentNode, //primaryNode
            _primaryNode, //parentNode
            NodeType.SUBDOMAIN, // nodeType
            _tokenId, //tokenId
            _parentRecord.tldId, //tldID
            block.timestamp, //createdAt
            block.timestamp //updatedAt
        ); 
    
        // lets create a reverse token id 
        _recordsNodeToId[_node] = _tokenId;
        _recordsByParent[_parentNode].push(_tokenId);

        _svgImagesProps[_node] = _svgProps;

        emit MintSubdomain(_tokenId, _to);
    }

    /**
     * @dev register a subDomain 
     * @param _label the name of the domain
     * @param _parentNode the parent node to create the subdomain from
     */
    function mintSubdomain(
        string   calldata   _label,
        bytes32             _parentNode,
        SvgProps  memory    _svgProps
    ) 
        public 
        onlyValidLabel(_label)
        returns(uint256, bytes32) 
    {
        require(ownerOf(getRecord(_parentNode).tokenId) == _msgSender(), "Registry#mintSubdomain: NOT_PARENT_OWNER");
        return _mintSubdomain(_label, _parentNode, _svgProps);
    }


    /**
     * getPrimaryNodeInfo
     *
    function primaryNodeInfo(bytes32 node)
        public
        view 
        returns (Record memory)
    {
        if(getRecord(node).nodeType == NodeType.DOMAIN){
            return getRecord(node);
        } else {
            return getRecord(getRecord(node).primaryNode);
        } 
    }*/

    /**
     * reverseNode
     */
    function reverseNode(bytes32 node) 
        public 
        view 
        returns(string memory)
    {

        if(getTLD(node).createdAt > 0){
            return getTLD(node).label;
        }

        bytes memory _result = abi.encodePacked("");

        while(true){
            
            Record memory _record = getRecord(node);

            _result =  abi.encodePacked(_result,".");

            if(getTLD(_record.parentNode).createdAt > 0 ){
                _result =  abi.encodePacked(_result, getTLD(_record.parentNode).label);
                break;
            } else {
                node = _record.parentNode;
            }
        }

        return string(_result);
    }

    /**
     * @dev returns the resolver 
     * @param node to return the resolver
     * @return address of the resolver 
     */
    function resolver(bytes32 node) public virtual view returns (IResolver) {
        return _resolver;
    }

    /**
     * @dev set resolver
     * @param _addr resolver address
     */
    function setResolver(address _addr)
        public 
        onlyAdmin
    {
        require(_addr != address(0), "Registry#setResolver: INVALID_ADDRESS");
        _resolver = IResolver(_addr);
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

    /**
     * @dev get the collection uri
     */
    function collectionUri() 
        external 
        view 
        returns (string memory)
    {
        return _collectionUri;
    }

    /**
     * @dev set collection Uri
     */
    function setCollectionUri(string memory uri) 
        public
        onlyAdmin
    {
        _collectionUri = uri;
        emit SetCollectionUri(uri);
    }


    /**
     * @dev get controller using node
     * @param node the bytes32 node of a domain
     */
    function controller(bytes32 node) 
        public 
        view 
        returns(address)
    {
        return _controllers[node]; 
    }


    /**
     * @dev or remove controller
     * @param _node the namehash of the domain
     */
    function setController(bytes32 _node, address account)
        public
        tokenExists(getRecord(_node).tokenId)
        onlyTokenOwner(getRecord(_node).tokenId)
    {
        _controllers[_node] = account;      
        emit SetController(_node, account);
    }

    //////////////////////////// Overrides Starts  //////////////////////////

    function _burn(uint256 tokenId)
        internal
        override(
            ERC721Upgradeable, 
            ERC721URIStorageUpgradeable,
            ERC721RoyaltyUpgradeable
        )
    {}

    /**
     * @dev get the token uri
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        
       bytes32 _node = _records[tokenId].namehash;

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
        
        Record memory recordInfo = _records[tokenId];

        require(recordInfo.createdAt > 0, "Registry#_beforeTokenTransfer: RECORD_NOT_FOUND");

        if(_tlds[recordInfo.tldId].tldType == TLD_TYPE_SOULBOUND){
            revert("Registry#_beforeTokenTransfer: NOT_TRANSFERABLE");
        }   

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
        
        Record memory _record = _records[tokenId];
        
        if(_record.nodeType == NodeType.DOMAIN){
            return super.ownerOf(tokenId);   
        }

        return super.ownerOf(getRecord(_record.primaryNode).tokenId); 
    }

    //////////////////////////// Overrides Ends  //////////////////////////

    uint256[50] private __gap;
}