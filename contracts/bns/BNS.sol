/** 
* BNBChain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "../utils/NameUtils.sol";
//import "contracts/Defs.sol"; // in IRegistry
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRegistry.sol";
import "../priceFeed/PriceFeed.sol";

contract BNS is 
    Defs,
    NameUtils,
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    PriceFeed
{

    event SetSigner(address indexed _oldSigner, address indexed  _newSigner);
    event AffiliateShare(address indexed _referrer, address indexed _paymentToken, uint256 _shareAmount);
    event RegisterDomain(string _tld, uint256 _tokenId, address indexed _to, address indexed _paymentToken, uint256 _amount);
    event SetPriceSlippageToleranceRate(uint256 _valueBPS);
    event AddTLD(string _name, address _addr, bytes32 _node);


    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    ////////////// Rgistries ///////////////
    // node => registry address 

    mapping(bytes32  => address) private _registry;
    bytes32[] private _registryIndexes;
    
    //// Payment Tokens //////

    // total payment tokens 
    uint256 _totalPaymentTokens;

    mapping(uint256 => PaymentTokenDef) private _paymentTokens;
    mapping(address => uint256) private _paymentTokensIndexes;
    ////// End Payment Token ////

    ///// Registered domains ////////
    
    uint256 _totalRegisteredDomains;

    mapping(uint256 => RegisteredDomainDef) private _registeredDomains;
    
    mapping(bytes32 => uint256) private _registeredDomainsNodeIndexes;

    // tld indexes
    mapping(bytes32 => uint256[]) private _registeredDomainsTLDIndexes;

    mapping(address => uint256[]) private _registeredDomainsAccountIndexes;

    ///  End Registered Domains //// 


    // request signer 
    address _signer;

    //check request authorization (default: true)
    bool _checkRequestAuth;

    // affiliate share 
    uint256 _affiliateSharePercent;

    // stable coin contract
    address _defaultStableCoinAddr;

    uint256 _priceSlippageToleranceRate;

    /**
     * @dev initialize the contract
     * @param requestSigner the address used for signing authorized request
     * @param defaultStableCoinAddr stable stablecoin address
     */
    function initialize(
        address requestSigner,
        address defaultStableCoinAddr
    ) 
        public 
        initializer
    {   
        __Context_init();
        __Ownable_init();

        _signer = requestSigner;
        _checkRequestAuth       = true;
        _affiliateSharePercent  = 500; // 5%  
        _defaultStableCoinAddr  = defaultStableCoinAddr;

        _priceSlippageToleranceRate = 50; // 0.5
    }

    /**
     * @dev addTLD adds a deployed tld info
     * @param _name the tld name 
     * @param _addr the tld contract address
     */
    function addTLD(
        string memory _name,
        address _addr
    )
        public 
        onlyOwner
        onlyValidLabel(_name)
    {

        bytes32 _node = getTLDNameHash(_name);

        require(_registry[_node] != address(0), "BNS#addTLD: TLD_ALREADY_EXISTS");

        _registry[_node] = _addr;

        _registryIndexes.push(_node);

        emit AddTLD(_name, _addr, _node);
    } //end


    /**
     * @dev getTLD fetch a told using the name
     * @param _tld the name of the tld 
     * @return _regInfo IRegistry
     */
    function getTLD(string memory _tld) 
        public
        view 
        returns (RegistryInfo memory _regInfo)
    {   
        bytes32 _node = getTLDNameHash(_tld);
        address registryAddr = _registry[_node];

        if(registryAddr == address(0)){
            return _regInfo;
        }    

        _regInfo = IRegistry(registryAddr).getRegistryInfo();
    } //end 


    /**
     * @dev getAllTLDs fetch a told using the name
     * @return IRegistry[]
     */
    function getAllTLDs() 
        public
        view 
        returns (RegistryInfo[] memory)
    {   

        RegistryInfo[] memory _regDataArray = new RegistryInfo[](_registryIndexes.length + 1);

        for(uint256 i=0; i<= _registryIndexes.length; i++) {
            _regDataArray[i] = IRegistry(_registry[_registryIndexes[i]]).getRegistryInfo();
        }

        return _regDataArray;
    }

    /**
     * @dev set Price deviation rate tolerance, the rate in % at which the price can fall to
     * @param valueBPS value in basis point 
     */
    function setPriceSlippageToleranceRate(uint256 valueBPS) 
        public 
        onlyOwner
    {
        _priceSlippageToleranceRate = valueBPS;
        emit SetPriceSlippageToleranceRate(valueBPS);
    }
    
    /**
     * @dev get a registry address
     * @param _tld the top level domain name in string example: cake
     * @return address 
     */
    function getRegistry(string memory _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[getTLDNameHash(_tld)];
    }

    /**
     * @dev get a registry address
     * @param _tld the top level domain name in bytes32 example: cake
     * @return address 
     */
    function getRegistry(bytes32 _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[_tld];
    }

    /**
     * @dev this retuens the resolver address when the node is provided
     * @param node the tld node in bytes32
     */
    function resolver(bytes32 node) public view returns (address) {
        return getRegistry(node);
    }

    /**
     * @dev register a domain
     * @param  _label the text part of the domain without the tld extension
     * @param _tld the domain tld part
     * @param paymentToken the contract address of the payment mode 0x0 for native 
     * @param affiliateAddr the affiliate address who refered the user
     */
    function registerDomain(
        string memory _label,
        string memory _tld,
        address paymentToken,
        address affiliateAddr
    )
        public
        onlyValidLabel(_tld)
        payable
    {
   
        address _tldRegistry = getRegistry(_tld);

        require(_tldRegistry != address(0), "BNSCore#registerDomain: INVALID_TLD");

        IRegistry _iregistry = IRegistry(_tldRegistry);

        uint256 amountUSDT = _iregistry.getPrice(_label);

        PaymentTokenDef memory _pTokenInfo = _paymentTokens[_paymentTokensIndexes[paymentToken]];

        uint256 tokenAmount = PriceFeed.toTokenAmount(amountUSDT, _pTokenInfo);

        if(paymentToken == address(0)) {

     
            if(_priceSlippageToleranceRate > 0){
                
                uint256 priceSlippageToleranceAmt = percentToAmount(_priceSlippageToleranceRate, tokenAmount);
                tokenAmount = (tokenAmount - priceSlippageToleranceAmt);
            }

            require(msg.value >= tokenAmount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

        } else {

            IERC20 _erc20 = IERC20(paymentToken);
            require( _erc20.balanceOf(_msgSender()) >= tokenAmount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

            require(_erc20.transferFrom(_msgSender(), address(this), tokenAmount), "BNSCore#AMOUNT_TRANSFER_FAILED");
        }

        //send affiliate payment
        processAffiliateShare(affiliateAddr, paymentToken, tokenAmount);
        

        (uint256 _tokenId, bytes32 _node) = _iregistry.addDomain(_msgSender(), _tld);

        uint256 _domainId = _totalRegisteredDomains++;

        _registeredDomains[_domainId] = RegisteredDomainDef({
            assetAddress:   _tldRegistry,
            tokenId:        _tokenId,
            node:           _node,
            userAddress:    _msgSender()
        });

        // add to user's domains collection
        _registeredDomainsAccountIndexes[_msgSender()].push(_domainId);

        // add to tld collection
        _registeredDomainsTLDIndexes[getTLDNameHash(_tld)].push(_domainId);

        _registeredDomainsNodeIndexes[_node] = _domainId;

        emit RegisterDomain(
            _tld,
            _tokenId,  
            _msgSender(), 
            paymentToken, 
            tokenAmount
        );

    } //end 

    /**
     * doTransfer
     */
    function transferToken(
        address tokenAddress, 
        address payable _from,
        address payable _to, 
        uint256 amount
    ) 
        private 
    {   
        if(tokenAddress == address(0)){

             (bool success, ) = _to.call{ value: amount }("");
            require(success, "TransferBase#transfer: NATIVE_TRANSFER_FAILED");

        } else {

            IERC20 _erc20 = IERC20(tokenAddress);

            require( _erc20.balanceOf(_msgSender()) >= amount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

            if(_from == address(this)){
                 require(_erc20.transfer(_to, amount), "BNSCore#ERC20_TRANSFER_FAILED");
            } else {
                require(_erc20.transferFrom(_from, _to, amount), "BNSCore#ERC20_TRANSFER_FROM_FAILED");
            }
        }
    }


    /**
     * processAffiliateShare 
     * @param _referrer address 
     * @param _amount uint256 
     */
    function processAffiliateShare(
        address _referrer, 
        address _paymentToken,
        uint256 _amount
    )
        private 
    {
        if(_referrer == address(0) || _amount == 0) return;

        uint256 _shareAmount = percentToAmount(_affiliateSharePercent, _amount);

        transferToken(_paymentToken, payable(address(this)), payable(_referrer), _shareAmount);

        emit AffiliateShare( _referrer, _paymentToken, _shareAmount);
    }

    /**
     * @dev Set signature signer.
     * @param signer_ the new signer
     */
    function setSigner(address signer_) external onlyOwner {

        require(signer_ != address(0), "BNSCore#setSigner: INVALID_ADDRESS");

        address _oldSigner = _signer;

        _signer = signer_;

        emit SetSigner(_oldSigner, _signer);
    }

    /**
     * @dev wether to enable or disable request authorization checks
     * @param _option true to enable, false to disable
     */
    function enableRequestAuthCheck(bool _option)  external onlyOwner {
        _checkRequestAuth = _option;
    }

      /**
     * @dev get chain id 
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev validate the request
     * @param _authInfo the authorization auth info
     * @param _requestHash the hash of the request params
     */
    function validateRequestAuth(RequestAuthInfo memory _authInfo, bytes32 _requestHash) internal view {
        if(_checkRequestAuth) {
            require(_authInfo.expiry > block.timestamp, "BNSCore: SIGNER_AUTH_EXPIRED");
            bytes32 msgHash = keccak256( abi.encodePacked(
                                            _authInfo.authKey,
                                            _msgSender(), 
                                            _authInfo.expiry, 
                                            _requestHash, 
                                            getChainId()
                                        ) 
                                );
            require(_signer == msgHash.recover(_authInfo.signature), "BNSCore: INVALID_SIGNATURE");
        }
    }


    /**
    * @dev convert percentage value in Basis Point System to amount or token value
    * @param _percentInBps the percentage calue in basis point system
    * @param _amount the amount to be used for calculation
    * @return final value after calculation in uint256
    */
    function percentToAmount(uint256 _percentInBps, uint256 _amount) internal pure returns(uint256) {
        //to get pbs,multiply percentage by 100
        return  (_amount.mul(_percentInBps)).div(10_000);
    }


    
    /**
     * @dev get domains by tld
     * @param indexesData indexes to fetch the ids
     * @param startIndex the id to start the data
     * @param endIndex  the id to end fetching data
     * @param sort there are two orders, 0 for ascending and 1 for descending
     */
    function _fetchDomainsByIndexes(
        uint256[] memory  indexesData,
        uint256     startIndex,
        uint256     endIndex,
        SortOrder   sort
    )
        private  
        view 
        returns (RegisteredDomainDef[] memory, Record[] memory) 
    {
         if(!(sort == SortOrder.ASCENDING_ORDER || sort == SortOrder.DESCENDING_ORDER)){
            sort = SortOrder.DESCENDING_ORDER;
        }

        uint256 _dataSize;
        uint256 _loopStart; 
        uint256 _loopEnds;

        uint256 dataLength = indexesData.length;

        if(dataLength == 0){
            return ( (new RegisteredDomainDef[](0)), (new Record[](0)) );
        }

        if(sort == SortOrder.ASCENDING_ORDER){
            if(endIndex >= dataLength) endIndex = dataLength;
            require(endIndex >= startIndex, "BNS#getRegisteredDomains: END_INDEX_MUST_EXCEED_START_INDEX_FOR_SORT_ASC");
            _dataSize = endIndex - startIndex;
            _loopStart = startIndex;
            _loopEnds = endIndex;
        } else {
            if(startIndex >= dataLength) startIndex = dataLength;
            require(startIndex >= endIndex, "BNS#getRegisteredDomains: START_INDEX_MUST_EXCEED_END_INDEX_FOR_SORT_DESC");
            _dataSize = startIndex - endIndex;
            _loopStart = endIndex;
            _loopEnds = startIndex;
        }

        uint256[] memory _dataIdsArray = new uint256[](_dataSize);

        uint256 _currentId = _loopStart;
        uint256 _counter;

        while(_currentId == _loopEnds) {
            _dataIdsArray[_counter] = indexesData[_currentId];
        }


        return fetchRegisteredDomainsByIds(_dataIdsArray);
    } //end function


    /**
     * @dev fetchRegisteredDomainsByIds
     * @param idsDataArray the ids data array
     */
    function fetchRegisteredDomainsByIds(
        uint256[] memory idsDataArray
    ) 
        public 
        view 
        returns(RegisteredDomainDef[] memory, Record[] memory)
    {
        uint dataLen = idsDataArray.length;

        RegisteredDomainDef[] memory _domainRegInfoArray = new RegisteredDomainDef[](dataLen);
        Record[] memory _domainRecordsArray = new Record[](dataLen);

        for(uint256 i = 0; i < dataLen; i++) {
            RegisteredDomainDef memory _rg = _registeredDomains[idsDataArray[i]];  
            if(_rg.assetAddress != address(0)) {
                _domainRegInfoArray[i] = _rg;
                _domainRecordsArray[i] = IRegistry(_rg.assetAddress).getRecord(_rg.node);
            }
        }

        return (_domainRegInfoArray, _domainRecordsArray);
    }


    /**
     * @dev fetchDomainsByTLD fetch domains by tld 
     * @param _tld tld node 
     * @param startIndex the data index to start with
     * @param endIndex  the end index to end with 
     * @param sort how to sort the data 
     */
    function fetchDOmainsByTLD(
        bytes32     _tld,
        uint256     startIndex,
        uint256     endIndex,
        SortOrder   sort
    ) 
        public 
        view 
        returns(RegisteredDomainDef[] memory, Record[] memory)
    {
        return _fetchDomainsByIndexes(_registeredDomainsTLDIndexes[_tld], startIndex, endIndex, sort);
    }

}