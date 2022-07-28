/** 
* BNBChain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "../utils/NameUtils.sol";
import "contracts/Defs.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRegistry.sol";

contract BNSCore is 
    Defs,
    NameUtils,
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
    
{

    event SetSigner(address indexed _oldSigner, address indexed  _newSigner);
    event AffiliateShare(address indexed _referrer, address indexed _paymentToken, uint256 _shareAmount);
    event RegisterDomain(string _tld, uint256 _tokenId, address indexed _to, address indexed _paymentToken, uint256 _amount);

    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // node => registry address 
    mapping(bytes32 => address) private _registry;
    bytes32[] private _registryIndexes;

    // request signer 
    address _signer;

    //check request authorization (default: true)
    bool _checkRequestAuth;

    // affiliate share 
    uint256 _affiliateSharePercent;

    /**
     * @dev initialize the contract
     * @param requestSigner the address used for signing authorized request
     */
    function initialize(
        address requestSigner
    ) 
        public 
        initializer
    {   
        __Context_init();
        __Ownable_init();

        _signer = requestSigner;
        _checkRequestAuth       = true;
        _affiliateSharePercent  = 500; // 5%  
    }
    
    function getRegistry(string memory _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[getTLDNameHash(_tld)];
    }

    function getRegistry(bytes32 _tld) 
        public 
        view 
        returns (address)
    {
        return _registry[_tld];
    }

    /**
     * ENS resolver 
     */
    function resolver(bytes32 node) public view returns (address) {
        return getRegistry(node);
    }

    /**
     * @dev register a domain
     */
    function registerDomain(
        string memory _label,
        string memory _tld,
        address paymentToken,
        //uint256 amount,
        address affiliateAddr
       // RequestAuthInfo memory _authInfo
    )
        public
        onlyValidLabel(_tld)
        payable
    {

        /*/ request hash 
        bytes32 paramHash = keccak256( abi.encodePacked(
            _label,
            _tld,
            paymentToken,
            amount,
            affiliateAddr
        ));

        // validate request auth 
        validateRequestAuth(_authInfo, paramHash);
        */

        address _tldRegistry = getRegistry(_tld);

        IRegistry _iregistry = IRegistry(_tldRegistry);


        require(_tldRegistry != address(0), "BNSCore#registerDomain: INVALID_TLD");

        if(amount > 0){
            if(paymentToken == address(0)) {
                require(msg.value >= amount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");
            } else {

                IERC20 _erc20 = IERC20(paymentToken);
                require( _erc20.balanceOf(_msgSender()) >= amount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

                require(_erc20.transferFrom(_msgSender(), address(this), amount), "BNSCore#AMOUNT_TRANSFER_FAILED");
            }

            //send affiliate payment
            processAffiliateShare(affiliateAddr, paymentToken, amount);
        }

        (uint256 _tokenId,) = _iregistry.addDomain(_msgSender(), _tld);

        emit RegisterDomain(
            _tld,
            _tokenId,  
            _msgSender(), 
            paymentToken, 
            amount
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

}