/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "./RegistrarBase.sol";
//import "contracts/Defs.sol"; // in IRegistry
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract PublicRegistrar is 
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable,
    MulticallUpgradeable,
    ReentrancyGuardUpgradeable,
    RegistrarBase 
{


    event SetSigner(address indexed _oldSigner, address indexed  _newSigner);
    event AffiliateShare(address indexed _referrer, address indexed _paymentToken, uint256 _shareAmount);
    event RegisterDomain(uint256 _domainId, address indexed _to, address indexed _paymentToken, uint256 _amount);
    event SetPriceSlippageToleranceRate(uint256 _valueBPS);
    event AddTLD(string _name, address _addr, bytes32 _node);
    event AddPaymentToken(uint256 _id, address _assetAddress);
    event SetTreasuryAddress(address _account);

    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev initialize the contract
     */
    function initialize(
        address requestSigner,
        address treasuryAddress_,
        address defaultStableCoin_
    ) 
        public 
        initializer
    {   

        require(defaultStableCoin_ != address(0), "BNS#initialize: defaultStableCoin_ cannot be a zero address");
        //require(treasuryAddress_ != address(0), "BNS#initialize: treasuryAddress_ cannot be a zero address");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Multicall_init_unchained();
        __ReentrancyGuard_init();

        if(requestSigner == address(0)){
            requestSigner = _msgSender();
        }

        _signer = requestSigner;
        _checkRequestAuth       = false;
        affiliateSharePercent   = 500; // 5%  
        defaultStableCoin       = defaultStableCoin_;
        treasuryAddress         = treasuryAddress_;

        _priceSlippageToleranceRate = 50; // 0.5
    }

     /**
     * @dev update treasury address
     * @param _account the treasury address
     */
    function setTreasuryAddress(address _account)
        public
        onlyOwner
    {
        treasuryAddress = _account;
        emit SetTreasuryAddress(_account);
    }

    /**
     * @dev update default stablecoin address
     * @param _assetAddress the stablecoin contract address
     */
    function setDefaultStableCoin(address _assetAddress)
        public
        onlyOwner
    {
        defaultStableCoin = _assetAddress;
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
     * @dev get chain id 
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }


    /////////////// PRICING  STARTS ///////////////
    
    /**
     * getPrices
     */
    function getPrices(string memory _tld) 
        public 
        view 
        onlyValidLabel(_tld)
        tldExists(_tld)
        returns (DomainPrices memory) 
    {
        return domainPrices[getTLDNameHash(_tld)];
    }

    /**
     * @dev get domain price 
     * @param _label the label part of a domain
     */
    function getPrice(
        string memory _tld,
        string memory _label
    ) 
        public 
        view
        onlyValidLabel(_tld)
        tldExists(_tld)
        onlyValidLabel(_label)
        returns(uint256)
    {   
        
        DomainPrices memory _domainPrices = getPrices(_tld);

        uint labelSize = bytes(_label).length;

        require(labelSize > 0, "BNSRegistry#LABEL_REQUIRED");

        uint256 _p;

        if(labelSize == 1)      _p = _domainPrices.one;
        else if(labelSize == 2) _p = _domainPrices.two;
        else if(labelSize == 3) _p = _domainPrices.three;
        else if(labelSize == 4) _p = _domainPrices.four;
        else                    _p = _domainPrices.fivePlus;

        return _p;
    }


    ////////////// PRICING ENDS //////////////////


    ////////////////// Domains counts /////////////

    /**
    * @dev get total domains by tld
    * @param _tld the tld name in lowercase string
    * @return the id in uint256
    */
    function getTotalDomainByTLD(string memory _tld)
        public 
        view 
        returns(uint256) 
    {
        return domainIdsByTLD[getTLDNameHash(_tld)].length;
    }

    /**
    * @dev get total domains by tld
    * @param _account the account we want
    * @return the id in uint256
    */
    function getTotalDomainsByAccount(address _account)
        public 
        view 
        returns(uint256) 
    {
        return domainIdsByAccount[_account].length;
    }

    /**
    * @dev get domain info by index
    */
    function getDomainByTLDIndex(
        string memory _tld,
        uint256 _idIndex
    )
        public 
        view 
        returns (DomainInfoDef memory, Record memory) 
    {
        return getDomainInfoById(domainIdsByTLD[getTLDNameHash(_tld)][_idIndex]);
    }

    /**
    * @dev get domain info by index
    */
    function getDomainByAccountIndex(
        address _account,
        uint256 _idIndex
    )
        public 
        view 
        returns (DomainInfoDef memory, Record memory) 
    {
        return getDomainInfoById(domainIdsByAccount[_account][_idIndex]);
    }

    /////////////////// END Domain info count /////////

    ////////////////// Request Auth ////////////////

    /**
     * @dev wether to enable or disable request authorization checks
     * @param _option true to enable, false to disable
     */
    function enableRequestAuthCheck(bool _option)  public onlyOwner {
        _checkRequestAuth = _option;
    }

      /**
     * @dev validate the request
     * @param _authInfo the authorization auth info
     */
    function validateRequestAuth(RequestAuthInfo memory _authInfo) internal view {
        if(_checkRequestAuth) {
            require(_authInfo.expiry > block.timestamp, "BNSCore: SIGNER_AUTH_EXPIRED");
            bytes32 msgHash = keccak256( abi.encodePacked(
                                            _authInfo.authKey,
                                            _msgSender(), 
                                            _authInfo.expiry, 
                                            getChainId()
                                        ) 
                                );
            require(_signer == msgHash.recover(_authInfo.signature), "BNSCore: INVALID_SIGNATURE");
        }
    }


    /**
     * @dev Set signature signer.
     * @param signer_ the new signer
     */
    function setSigner(address signer_) public onlyOwner {

        require(signer_ != address(0), "BNSCore#setSigner: INVALID_ADDRESS");

        address _oldSigner = _signer;

        _signer = signer_;

        emit SetSigner(_oldSigner, _signer);
    }

    /////////// Request Auth Ends ////////////

    /////// TLD functions Starts //////

     /**
     * @dev addTLD adds a deployed tld info
     * @param _domainExt the tld domain extension name 
     * @param _assetAddress the tld contract address
     * @param _domainPrices the domain prices 
     */
    function addTLD(
        string memory       _domainExt,
        address             _assetAddress,
        DomainPrices memory _domainPrices
    )
        public 
        onlyOwner
        onlyValidLabel(_domainExt)
    {

        bytes32 _node = getTLDNameHash(_domainExt);

        require(registryInfo[_node] == address(0), "BNS#addTLD: TLD_ALREADY_EXISTS");

        registryInfo[_node] = _assetAddress;
        domainPrices[_node] = _domainPrices;

        registryIds.push(_node);

        emit AddTLD(_domainExt, _assetAddress, _node);
    } //end

    /**
     * @dev getTotalTLDs - get total tlds 
     */
    function getTotalTLDs() public view returns(uint256){
        return registryIds.length;
    }


    /**
     * @dev getTLD fetch a told using the name
     * @param _tld the name of the tld 
     * @return _regInfo IRegistry
     */
    function getTLD(string memory _tld) 
        public
        view 
        returns (
            RegistryInfo memory _regInfo,
            DomainPrices memory _domainPrices
        )
    {   
        bytes32 _node = getTLDNameHash(_tld);
        address registryAddr = registryInfo[_node];

        if(registryAddr == address(0)){
            return (_regInfo, _domainPrices);
        }    

        _domainPrices = domainPrices[_node];
        _regInfo = IRegistry(registryAddr).getRegistryInfo();
    } //end 


    /**
     * @dev getAllTLDs fetch a told using the name
     * @return IRegistry[]
     */
    function getAllTLDs() 
        public
        view 
        returns (
            RegistryInfo[] memory,
            DomainPrices[] memory
        )
    {   

        RegistryInfo[] memory _regDataArray = new RegistryInfo[](registryIds.length);
        DomainPrices[] memory _domainPrices = new DomainPrices[](registryIds.length);

        for(uint256 i=0; i < registryIds.length; i++) {
            _regDataArray[i] = IRegistry(registryInfo[registryIds[i]]).getRegistryInfo();
            _domainPrices[i] = domainPrices[registryIds[i]];
        }

        return (_regDataArray, _domainPrices);
    }
    /////////// END TLD Functions ///////////

    /////////////// Registry Start /////////////

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
        return registryInfo[getTLDNameHash(_tld)];
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
        return registryInfo[_tld];
    }

    /**
     * @dev this retuens the resolver address when the node is provided
     * @param node the tld node in bytes32
     */
    function resolver(bytes32 node) public view returns (address) {
        return getRegistry(node);
    }
    ///////////// Registry Ends ///////////////

    /**
     * @dev register a domain
     * @param  _label the text part of the domain without the tld extension
     * @param _tld the domain tld part
     * @param paymentToken the contract address of the payment mode 0x0 for native 
     * @param affiliateAddr the affiliate address who refered the user
     */
    function registerDomain(
        string                      memory _label,
        string                      memory _tld,
        address                     paymentToken,
        address                     affiliateAddr,
        SvgImageProps   memory      svgImgInfo, // background info
        RequestAuthInfo memory      authInfo 
    )
        public
        onlyValidLabel(_tld)
        tldExists(_tld)
        nonReentrant()
        payable
    {   

        validateRequestAuth(authInfo);
   
        require(getRegistry(_tld) != address(0), "BNS#registerDomain: INVALID_TLD");

        IRegistry _iregistry = IRegistry(getRegistry(_tld));

        //uint256 amountUSD = getPrice(_tld, _label);

        PaymentTokenDef memory _pTokenInfo = paymentTokens[paymentTokensIndexes[paymentToken]];

        require(_pTokenInfo.tokenAddress != address(0), "BNS#registerDomain: INVALID_PAYMENT_TOKEN");

        uint256 tokenAmount = PriceFeed.toTokenAmount(getPrice(_tld, _label), _pTokenInfo);

        if( paymentToken == nativeAssetAddress ) {

     
            if(_priceSlippageToleranceRate > 0){
                
                uint256 priceSlippageToleranceAmt = percentToAmount(_priceSlippageToleranceRate, tokenAmount);
                tokenAmount = (tokenAmount - priceSlippageToleranceAmt);
            }

            require(msg.value >= tokenAmount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

        } else {

            IERC20 _erc20 = IERC20(paymentToken);
            require( _erc20.balanceOf(_msgSender()) >= tokenAmount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");
            require(IERC20(paymentToken).transferFrom(_msgSender(), address(this), tokenAmount), "BNSCore#AMOUNT_TRANSFER_FAILED");
        }

        //send affiliate payment
        uint256 affiliateShareAmt = processAffiliateShare(affiliateAddr, paymentToken, tokenAmount);
        
        // lets send the rest to treasury 
        if(treasuryAddress != address(0)){
            transferToken(
                paymentToken, 
                payable(address(this)), 
                payable(treasuryAddress), 
                (tokenAmount.sub(affiliateShareAmt)) 
            );
        }

        // register the domain
        (uint256 _tokenId, bytes32 _node) = _iregistry.addDomain(_msgSender(), _label, svgImgInfo);

        // increment and assign +1
        uint256 _domainId = ++totalDomains;

        domainsInfo[_domainId] = DomainInfoDef({
            assetAddress:   getRegistry(_tld),
            tokenId:        _tokenId,
            node:           _node,
            userAddress:    _msgSender()
        });

        // add to user's domains collection
        domainIdsByAccount[_msgSender()].push(_domainId);

        // add to tld collection
        domainIdsByTLD[getTLDNameHash(_tld)].push(_domainId);

        domainIdByNode[_node] = _domainId;

        emit RegisterDomain(
            _domainId,  
            _msgSender(), 
            paymentToken, 
            tokenAmount
        );

    } //end 

    /**
     * @dev handle transfer
     * @param tokenAddress the token asset contract
     * @param _from the originating address
     * @param _to the destination address
     * @param amount the amount to send
     */
    function transferToken(
        address tokenAddress, 
        address payable _from,
        address payable _to, 
        uint256 amount
    ) 
        private 
    {   
        if(tokenAddress == nativeAssetAddress){

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
        returns(uint256) 
    {
        if(_referrer == address(0) || _amount == 0) return 0;

        uint256 _shareAmount = percentToAmount(affiliateSharePercent, _amount);

        transferToken(_paymentToken, payable(address(this)), payable(_referrer), _shareAmount);

        emit AffiliateShare( _referrer, _paymentToken, _shareAmount);

        return _shareAmount;
    }

    /**
     * @dev get domain by id
     * @param _id the domain Id 
     */
    function getDomainInfoById(uint256 _id)
        public 
        view 
        returns (DomainInfoDef memory, Record memory) 
    {
        DomainInfoDef memory _rg = domainsInfo[_id];
        Record memory _domainRecord;

        if(_rg.assetAddress == address(0)) {
            return ( _rg, _domainRecord );
        }

        _domainRecord = IRegistry(_rg.assetAddress).getRecord(_rg.node);

        return (_rg, _domainRecord);
    }
    

    /**
     * @dev get domain info by node
     * @param _node the domain node
     */
    function getDomainInfoByNode(bytes32 _node)
        public 
        view 
        returns (DomainInfoDef memory, Record memory) 
    {
        return getDomainInfoById(domainIdByNode[_node]);
    }


    /**
     * @dev addPaymentToken - add a payment token
     * @param _pTokenInfo - PaymentTokenDef
     */
    function addPaymentToken(PaymentTokenDef memory _pTokenInfo )
        public 
        onlyOwner
    {
        if(_pTokenInfo.priceFeedSource == "chainlink"){
            require(_pTokenInfo.priceFeedContract == address(0), "BNS#addPaymentToken: CHAINLINK_FEED_CONTRACT_REQUIRED");
        }
        
        require(
            !(_pTokenInfo.dexInfo.factory == address(0) || _pTokenInfo.dexInfo.router == address(0)), 
            "BNS#addPaymentToken: CHAINLINK_FEED_CONTRACT_REQUIRED"
        );

        address _tokenAddress = _pTokenInfo.tokenAddress;

        if(_tokenAddress == nativeAssetAddress){
            _tokenAddress = getWETH(_pTokenInfo.dexInfo.router);
        }

        _pTokenInfo.dexInfo.pricePairToken =  getUniswapPairToken(
            _pTokenInfo.dexInfo.factory,
            _tokenAddress,
            defaultStableCoin
        );

       uint256 _pTokenId = ++totalPaymentTokens;

        paymentTokens[_pTokenId] = _pTokenInfo;
        paymentTokensIndexes[_pTokenInfo.tokenAddress] = _pTokenId;

        emit AddPaymentToken(_pTokenId, _pTokenInfo.tokenAddress);
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
     * @dev withdraw token - if users mistakenly send token to contract
     * @param _assetAddress the asset contract address
     * @param _to the destination address
     */
    function withdrawToken(
        address _assetAddress,
        address _to
    )
        public 
        onlyOwner 
    {
        IERC20 _erc20 = IERC20(_assetAddress);
        require(_erc20.balanceOf(address(this)) > 0, "BNS#withdrawToken: ZERO_BALANCE");
        _erc20.transfer(_to, _erc20.balanceOf(address(this)));
    }

     /**
     * @dev withdraw ethers - if users mistakenly send ethers or native asset to contract
     * @param _to the destination address
     */
    function withdrawEthers(
        address payable _to
    )
        public 
        onlyOwner 
    {

        uint256 _bal = address(this).balance;
        require(_bal > 0, "BNS#withdrawEthers: ZERO_BALANCE");

        (bool success, ) = _to.call{ value: _bal }("");
        require(success, "TransferBase#transfer: NATIVE_TRANSFER_FAILED");
    }
}   