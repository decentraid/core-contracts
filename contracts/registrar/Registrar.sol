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
import "hardhat/console.sol";

contract Registrar is 
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
    event RegisterTLD(address _registry);
    event AddPaymentToken(uint256 _id, address _assetAddress);
    event SetTreasuryAddress(address _account);
    event SetRegistry(address _addr);
    event SetAffiliateShare(uint256 _valueBps);
    event LockToMint(uint256 _domainId);
    event LockToMintReleaseTokens(uint256 id);
 
    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev initialize the contract
     */
    function initialize(
        address registryAddr,
        address requestSigner,
        address treasuryAddress_,
        address _labelValidatorAddr,
        address _lockToMinTokenAddr
    ) 
        public 
        initializer
    {   

        __Context_init_unchained();
        __Ownable_init_unchained();
        __Multicall_init_unchained();
        __ReentrancyGuard_init();

        if(requestSigner == address(0)){
            requestSigner = _msgSender();
        }

        _signer = requestSigner;
        _checkRequestAuth       =   false;
        affiliateSharePercent   =   500; // 5%  
        treasuryAddress         =   treasuryAddress_;

        _priceSlippageToleranceRate = 10; // 0.1%

        _nameLabelValidator = ILabelValidator(_labelValidatorAddr);

        _registry = IRegistry(registryAddr);

        nativeAssetAddress  = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        lockToMintTokenAddr    =   _lockToMinTokenAddr;

        isLockToMintEnabled    =   true;

        lockToMintMinimumRequiredTokens = 5_000 * (10 ** 18);
        
        lockToMintLockPeriod   =    90 days;
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
     * @dev update treasury address
     * @param _addr the treasury address
     */
    function setRegistry(address _addr)
        public
        onlyOwner
    {
        require(_addr != address(0), "Registrar#setRegistry: INVALID_REGISTRY_ADDRESS");

        _registry = IRegistry(_addr);
        emit SetRegistry(_addr);
    }

    /**
     * @dev set the affiliate share in bps
     * @param _valueBps the value in basis point
     */
    function setAffiliateShare(uint256 _valueBps)
        public
        onlyOwner
    {
       affiliateSharePercent = _valueBps;
        emit SetAffiliateShare(_valueBps);
    } 

    /**
     * @dev enable or disable lock to mint
     * @param _option wether true or false 
     */
    function enableLockToMint(bool _option)
        public
        onlyOwner
    {
        isLockToMintEnabled = _option;
    }

    /**
     * @dev set the total tokens required for lock
     * @param minTokensQty the minimum required tokens for the cheapest domain _5pchars
     */
    function setLockToMintMinimumRequiredTokens(
       uint256 minTokensQty
    ) 
        public
        onlyOwner
    {
        lockToMintMinimumRequiredTokens = minTokensQty;
    }

    /**
     * @dev lock to mint lock period
     * @param _timestampInSecs the lock time interval in unix timestamp seconds
     */
    function setLockToMintLockPeriod(
        uint256 _timestampInSecs
    ) 
        public
        onlyOwner
    {
        lockToMintLockPeriod = _timestampInSecs;
    }

    /**
     * @dev lock to mint token address
     * @param _addr erc20 token address
     */
    function setLockToMintTokenAddr(
        address _addr
    ) 
        public
        onlyOwner
    {
        lockToMintTokenAddr = _addr;
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


    ////////////////// Domains counts /////////////

    /**
     * @dev get domain by id
     * @param _id the domain Id 
     */
    function getNodeById(uint256 _id)
        public 
        view 
        returns (RegistrarNodeInfo memory, Node memory, TLDInfo memory) 
    {
        RegistrarNodeInfo memory _rg = _registrarNodesData[_id];
        Node memory _nodeInfo;

        _nodeInfo =_registry.getNode(_rg.node);
        
        TLDInfo memory _tldInfo = _registry.getTLD(_rg.tld);

        return (_rg, _nodeInfo, _tldInfo);
    }

    /**
     * @dev get domain by node
     * @param _node the domain Id 
     */
    function getNodeByHash(bytes32 _node)
        public 
        view 
        returns (RegistrarNodeInfo memory, Node memory, TLDInfo memory) 
    {   

        RegistrarNodeInfo memory _rg = _registrarNodesData[_nodeHashToIdMap[_node]];

        return (
            _rg, 
            _registry.getNode(_node),
            _registry.getTLD(_rg.tld)
        );
    }


    /** 
    * @dev get total domains by account
    */
    function getTotalDomainsByTLD(
        bytes32 _tld
    )
        public 
        view 
        returns (uint256) 
    {
        return domainIdsByTLD[_tld].length;
    }

    /**
    * @dev get domain info by index
    */
    function getDomainByTLDIndex(
        string memory _tld,
        uint256 _index
    )
        public 
        view 
        returns (RegistrarNodeInfo memory, Node memory, TLDInfo memory) 
    {
        return getNodeById(domainIdsByTLD[getTLDNameHash(_tld)][_index]);
    }


    /** 
     * @dev get total domains by account
     */
    function getTotalDomainsByAcct(
        address _account
    )
        public 
        view 
        returns (uint256) 
    {
        return domainIdsByAccount[_account].length;
    }

    /**
    * @dev get domain info by index
    */
    function getDomainByAcctIndex(
        address _account,
        uint256 _index
    )
        public 
        view 
        returns (RegistrarNodeInfo memory, Node memory, TLDInfo memory) 
    {
        return getNodeById(domainIdsByAccount[_account][_index]);
    }

    /////////////////// END Domain info count /////////

    ////////////////// Request Auth ////////////////

    /**
     * @dev wether to enable or disable request authorization checks
     * @param _option true to enable, false to disable
     */
    function enableRequestAuth(bool _option)  public onlyOwner {
        _checkRequestAuth = _option;
    }

    /**
     * @dev validate the request
     * @param _authInfo the authorization auth info
     */
    function validateRequestAuth(RequestAuthInfo memory _authInfo) internal view {
        if(_checkRequestAuth) {
            require(_authInfo.expiry > block.timestamp, "Registrar#RequestAuth: SIGNER_AUTH_EXPIRED");
            bytes32 msgHash = keccak256( abi.encodePacked(
                                            _authInfo.authKey,
                                            _msgSender(), 
                                            _authInfo.expiry, 
                                            getChainId()
                                        ) 
                                );
            require(_signer == msgHash.recover(_authInfo.signature), "Registrar#RequestAuth: INVALID_SIGNATURE");
        }
    }


    /**
     * @dev Set signature signer.
     * @param signer_ the new signer
     */
    function setSigner(address signer_) public onlyOwner {

        require(signer_ != address(0), "Registrar#PsetSigner: INVALID_ADDRESS");

        address _oldSigner = _signer;

        _signer = signer_;

        emit SetSigner(_oldSigner, _signer);
    }

    //////////// END Auth ///////////////////
    
    //////////////////// Payment Tokens //////////////////////

    /**
     * @dev addPaymentToken - add a payment token
     * @param _pTokenInfo - PaymentTokenDef
     */
    function addPaymentToken(PaymentTokenDef memory _pTokenInfo)
        public 
        onlyOwner
    {
        
        require(_pTokenInfo.priceFeedContract != address(0), "Registrar#addPaymentToken: CHAINLINK_FEED_CONTRACT_REQUIRED");

        address _tokenAddress = _pTokenInfo.tokenAddress;
   
        uint256 _pTokenId = totalPaymentTokens++;

        paymentTokens[_pTokenId] = _pTokenInfo;
        paymentTokensIndexes[_tokenAddress] = _pTokenId;

        emit AddPaymentToken(_pTokenId, _tokenAddress);
    }

    /**
     * @dev fetch all payment tokens  IERC20Metadata[] memory
     */
    function getPaymentTokens()
        public 
        view 
        returns (PaymentTokenInfo[] memory)
    {
        
        PaymentTokenInfo[] memory pTokenInfoArray   = new PaymentTokenInfo[](totalPaymentTokens);

       for(uint256 i = 0; i < totalPaymentTokens; i++) {
            if( paymentTokens[i].tokenAddress == nativeAssetAddress ){
                pTokenInfoArray[i] =  PaymentTokenInfo({
                    name:           "NATIVE_TOKEN_NAME",
                    symbol:         "NATIVE_TOKEN_SYMBOL",
                    decimals:       18,
                    paymentToken:   paymentTokens[i],
                    feedInfo:       getChainLinkPrice(paymentTokens[i].priceFeedContract)
                });
            } else {

                IERC20Metadata _tokenMeta = IERC20Metadata(paymentTokens[i].tokenAddress);
                pTokenInfoArray[i] =  PaymentTokenInfo({
                    name:           _tokenMeta.name(),
                    symbol:         _tokenMeta.symbol(),
                    decimals:       _tokenMeta.decimals(),
                    paymentToken:   paymentTokens[i],
                    feedInfo:       getChainLinkPrice(paymentTokens[i].priceFeedContract)
                });
            }
       }
       
       return pTokenInfoArray;
    } //end function

    /////////////////// End Payment Tokens //////////////////


    function getTLD(string memory _tld)
        public 
        view
        returns(TLDInfo memory)
    {
        return _registry.getTLD(getTLDNameHash(_tld));
    }

    /**
     * @dev get registry
     */
    function getRegistry()
        public
        view 
        returns(address)
    {
        return address(_registry); //registries[getTLDNameHash(_tld)];
    }

    /**
     * @dev getPrice
     */
     function getPrice(string memory _label, string memory _tld)
        public 
        view 
        returns(uint256 _price)
    {
        
        TLDInfo memory _tldInfo = _registry.getTLD(getTLDNameHash(_tld));

        uint labelLen = bytes(_label).length;

        if(labelLen == 1)      _price = _tldInfo.prices._1char;
        else if(labelLen == 2) _price = _tldInfo.prices._2chars;
        else if(labelLen == 3) _price = _tldInfo.prices._3chars;
        else if(labelLen == 4) _price = _tldInfo.prices._4chars;
        else                   _price = _tldInfo.prices._5pchars;
    }

    /**
     * @dev register a domain
     * @param  _label the text part of the domain without the tld extension
     * @param _tld the domain tld part
     * @param paymentToken the contract address of the payment mode 0x0 for native 
     * @param affiliateAddr the affiliate address who refered the user
     */
    function registerDomain(
        string                      memory  _label,
        string                      memory  _tld,
        address                     paymentToken,
        address                     affiliateAddr,
        SvgProps        memory      _svgProps // background info
    )
        public
        onlyValidLabel(_tld)
        TLDExists(_tld)
        nonReentrant()
        payable
    {   

        //validateRequestAuth(authInfo);
   
        require(getRegistry() != address(0), "Registrar#registerDomain: INVALID_TLD");

        //IRegistry _iregistry = IRegistry(getRegistry(_tld));

        //uint256 amountUSD = getPrice(_tld, _label);

        PaymentTokenDef memory _pTokenInfo = paymentTokens[paymentTokensIndexes[paymentToken]];

        require(_pTokenInfo.tokenAddress != address(0), "Registrar#registerDomain: INVALID_PAYMENT_TOKEN");

        
        uint _ptokenDecimals = (_pTokenInfo.tokenAddress == nativeAssetAddress) 
                                ? 18 
                                : IERC20Metadata(_pTokenInfo.tokenAddress).decimals();

        uint256 tokenAmount = PriceFeed.toTokenAmount(
                                    getPrice(_label, _tld), 
                                    _pTokenInfo,
                                    _ptokenDecimals
                                );

        //console.log("tokenAmount########=======>>>>>", tokenAmount);

        require(tokenAmount > 0, "Registrar#registerDomain: Payment amount cannot be 0");

        if( paymentToken == nativeAssetAddress ) {

     
            if(_priceSlippageToleranceRate > 0){
                
                uint256 priceSlippageToleranceAmt = percentToAmount(_priceSlippageToleranceRate, tokenAmount);
                tokenAmount = (tokenAmount - priceSlippageToleranceAmt);
            }

            require(msg.value >= tokenAmount, "Registrar#registerDomain: INSUFFICIENT_AMOUNT_VALUE");

        } else {

            //console.log("IERC20(paymentToken).balanceOf(_msgSender())", IERC20(paymentToken).balanceOf(_msgSender()));
            //console.log("tokenAmount==========================>>>>>>>>", tokenAmount);

            require( IERC20(paymentToken).balanceOf(_msgSender()) >= tokenAmount, "Registrar#registerDomain: INSUFFICIENT_BALANCE");
            require(IERC20(paymentToken).transferFrom(_msgSender(), address(this), tokenAmount), "Registrar#registerDomain: AMOUNT_TRANSFER_FAILED");
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
        (
            uint256 _tokenId, 
            bytes32 _node
        ) = _registry.mintDomain( _msgSender(), _label, _tld, _svgProps );

        // increment and assign +1
        uint256 _domainId = ++totalDomains;

        _registrarNodesData[_domainId] = RegistrarNodeInfo({
            assetAddress:   getRegistry(),
            tokenId:        _tokenId,
            node:           _node,
            tld:            getTLDNameHash(_tld),
            userAddress:    _msgSender()
        });

        // add to user's domains collection
        domainIdsByAccount[_msgSender()].push(_domainId);

        // add to tld collection
        domainIdsByTLD[getTLDNameHash(_tld)].push(_domainId);

        _nodeHashToIdMap[_node] = _domainId;

        emit RegisterDomain(
            _domainId,  
            _msgSender(), 
            paymentToken, 
            tokenAmount
        );

    } //end 


    /**
     * @dev lock to mint, lock an erc20 token for a specific period to mint
     * @param  _label the text part of the domain without the tld extension
     * @param _tld the domain tld part
     */
     function lockToMint(
        string      memory  _label,
        string      memory  _tld,
        SvgProps    memory  _svgProps, // image info
        ERC2612PermitDef memory _permit
    )
        public
        onlyValidLabel(_tld)
        TLDExists(_tld)
        nonReentrant()
    { 

        require(isLockToMintEnabled == true, "Registrar#lockToMint: lock to mint disabled");

        require(lockToMintTokenAddr != address(0), "Registrar#lockToMint: token to lock contract not set, report to dev");

         require(lockToMintLockPeriod > 0, "Registrar#lockToMint: lock period not set, report to dev");

        require(getRegistry() != address(0), "Registrar#lockToMint: invalid TLD");

        //tokens to lock 
        uint256 tokenQtyToLock = getLockToMintRequiredTokens(_label, _tld);
        
        require(tokenQtyToLock > 0, "Registrar#lockToMint: Token quantity to lock cannot be 0, report to dev");
        
        IERC20P erc20LockToken = IERC20P(lockToMintTokenAddr);

        require( 
            erc20LockToken.balanceOf(_msgSender()) >= tokenQtyToLock, 
            string(abi.encodePacked(
                "Registrar#lockToMint:", 
                tokenQtyToLock, 
                " ", 
                IERC20Metadata(lockToMintTokenAddr).symbol(), 
                " is required for locking"
            ))
        );

        // permit 
        erc20LockToken.permit(
            _permit.owner, 
            _permit.spender, 
            tokenQtyToLock,
            _permit.deadline,
            _permit.v,
            _permit.r,
            _permit.s
        );

        require(
            erc20LockToken.transferFrom(_msgSender(), address(this), tokenQtyToLock),
            "Registrar#lockToMint: TOKEN_TRANSFER_FAILED"
        );

        bytes32 tldNameHash = getTLDNameHash(_tld);

        // increment and assign +1
        uint256 _domainId = ++totalDomains;

        uint256 _lockToMintId = ++totalLockToMintEntries;

        lockToMintDataMap[_lockToMintId] = LockToMintInfoDef({
            id:             _lockToMintId,
            tokenAddress:   lockToMintTokenAddr,
            owner:          _msgSender(),
            quantity:       tokenQtyToLock,
            lockedAt:       block.timestamp,
            lockPeriod:     lockToMintLockPeriod,
            domainId:       _domainId,
            claimed:        false,
            claimedAt:      0
        });

        // save data
        lockToMintIdsByAccount[_msgSender()].push(_lockToMintId);
        lockToMintIdsByTLD[tldNameHash].push(_lockToMintId); 

        domainIdToLockToMintEntryId[_domainId] = _lockToMintId;

        // register the domain
        (
            uint256 _tokenId, 
            bytes32 _node
        ) = _registry.mintDomain( _msgSender(), _label, _tld, _svgProps );


        _registrarNodesData[_domainId] = RegistrarNodeInfo({
            assetAddress:   getRegistry(),
            tokenId:        _tokenId,
            node:           _node,
            tld:            tldNameHash,
            userAddress:    _msgSender()
        });


        // add to user's domains collection
        domainIdsByAccount[_msgSender()].push(_domainId);

        // add to tld collection
        domainIdsByTLD[tldNameHash].push(_domainId);

        _nodeHashToIdMap[_node] = _domainId;

        //domainIdsByLockToMint.push(_domainId);

        emit LockToMint(_domainId);
    }//end lock to mint


    /**
     * @dev lockToMint release locked tokens
     * @param id the lock to mint id
     */
    function lockToMintReleaseTokens(uint256 id)
        public 
    {
        LockToMintInfoDef memory lt = lockToMintDataMap[id];

        require(lt.lockedAt > 0, "Registrar: entry not found");
        require(lt.owner == _msgSender(), "Registrar: not owner");
        require((block.timestamp - lt.lockedAt) > lt.lockPeriod, "Registrar: unlock period is not due");
        require(lt.claimed == false, "Registrar: already claimed");

        //lets now resend user's token
        require(
            IERC20(lt.tokenAddress).transferFrom(address(this), lt.owner, lt.quantity),
            "Registrar#lockToMint: TOKEN_TRANSFER_FAILED"
        );

        lockToMintDataMap[id].claimed = true;
        lockToMintDataMap[id].claimedAt = block.timestamp;

        emit LockToMintReleaseTokens(id);
    } //end 

    /**
     * @dev get lock to mint quantity
     */
    function getLockToMintRequiredTokens(
        string   memory  _label,
        string   memory  _tld
    )
        public 
        view 
        returns (uint256 _qty)
    {

        TLDInfo memory _tldInfo = _registry.getTLD(getTLDNameHash(_tld));
      
        uint256 priceFor5pchars = _tldInfo.prices._5pchars;

        uint256 domainPrice = getPrice(_label, _tld);

        if(priceFor5pchars == 0 || domainPrice == 0) return 0;

        return (domainPrice / priceFor5pchars) * lockToMintMinimumRequiredTokens;
    }

    /*
     * @dev get mint to lock entry
     * @param id the entry id
     */
    function  getLockToMintEntryById(uint256 id) 
        public 
        view 
        returns (
            LockToMintInfoDef memory lockedEntry, 
            RegistrarNodeInfo memory _domainInfo,
            Node memory _recordInfo
        ) 
    {
        lockedEntry = lockToMintDataMap[id];

        if(lockedEntry.lockedAt == 0) {
            return (lockedEntry, _domainInfo, _recordInfo);
        }

        (_domainInfo, _recordInfo, ) = getNodeById(lockedEntry.domainId);
    }

    /**
     * @dev get total lock to mint entries by account addr
     * @param _account the account address
     */
    function  getLockToMintTotalEntriesByAccount(
        address _account
    ) 
        public 
        view 
        returns(uint256)
    {
        return lockToMintIdsByAccount[_account].length;
    }

    /**
     * @dev get the lock to mint entry by account indexed ids
     * @param _account user account id
     * @param _index the index of lockToMintIdsByAccount 
     */
    function  getLockToMintEntryByAccountIndex(
        address _account,
        uint256 _index
    ) 
        public 
        view
        returns (
            LockToMintInfoDef memory, 
            RegistrarNodeInfo memory,
            Node memory 
        ) 
    {
        return getLockToMintEntryById(lockToMintIdsByAccount[_account][_index]);
    }

    /**
     * @dev get total lock to min entries by tld
     * @param _tld the tld name
     */
    function  getLockToMintTotalEntriesByTLD(
        string memory _tld
    ) 
        public 
        view 
        returns(uint256)
    {
        return lockToMintIdsByTLD[getTLDNameHash(_tld)].length;
    }

     /**
     * @dev get the lock to mint entry by tld ids index
     * @param _tld the tld label
     * @param _index the index of lockToMintIdsByTLD 
     */
    function  getLockToMintEntryByTLDIndex(
        string memory _tld,
        uint256 _index
    ) 
        public 
        view
        returns (
            LockToMintInfoDef memory, 
            RegistrarNodeInfo memory,
            Node memory 
        ) 
    {
        return getLockToMintEntryById(lockToMintIdsByTLD[getTLDNameHash(_tld)][_index]);
    }


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
            require(success, "Registrar#transferToken: NATIVE_TRANSFER_FAILED");

        } else {

            IERC20 _erc20 = IERC20(tokenAddress);

            require( _erc20.balanceOf(_msgSender()) >= amount, "Registrar#INSUFFICIENT_AMOUNT_VALUE");

            if(_from == address(this)){
                 require(_erc20.transfer(_to, amount), "Registrar#transferToken: ERC20_TRANSFER_FAILED");
            } else {
                require(_erc20.transferFrom(_from, _to, amount), "Registrar#transferToken: ERC20_TRANSFER_FROM_FAILED");
            }
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
     * @dev move token - if users mistakenly send token to contract
     * @param _assetAddress the asset contract address
     * @param _to the destination address
     */
    function moveTokens(
        address _assetAddress,
        address _to
    )
        public 
        onlyOwner 
    {
        IERC20 _erc20 = IERC20(_assetAddress);
        require(_erc20.balanceOf(address(this)) > 0, "Registrar#withdrawToken: ZERO_BALANCE");
        _erc20.transfer(_to, _erc20.balanceOf(address(this)));
    }

     /**
     * @dev move ethers - if users mistakenly send ethers or native asset to contract
     * @param _to the destination address
     */
    function moveEthers(
        address payable _to
    )
        public 
        onlyOwner 
    {

        uint256 _bal = address(this).balance;
        require(_bal > 0, "Registrar#moveEthers: ZERO_BALANCE");

        (bool success, ) = _to.call{ value: _bal }("");
        require(success, "Registrar#moveEthers: NATIVE_TRANSFER_FAILED");
    }

}