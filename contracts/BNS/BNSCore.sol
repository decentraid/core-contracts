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

contract BNSCore is 
    Defs,
    NameUtils,
    Initializable,
    ContextUpgradeable,
    OwnableUpgradeable
    
{

    event SetSigner(address indexed _oldSigner, address indexed  _newSigner);

    using SafeMathUpgradeable for uint256;
    using ECDSAUpgradeable for bytes32;

    // node => registry address 
    mapping(bytes32 => address) private _registry;
    bytes32[] private _registryIndexes;

    // request signer 
    address _signer;

    //check request authorization (default: true)
    bool _checkRequestAuth;

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
        _checkRequestAuth = true;
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
        uint256 amount,
        RequestAuthInfo memory _authInfo
    )
        public
        payable
    {

        // request hash 
        bytes32 paramHash = keccak256( abi.encodePacked(
            _label,
            _tld,
            paymentToken,
            amount
        ));

        // validate request auth 
        validateRequestAuth(_authInfo, paramHash);

        if(paymentToken == address(0)) {
             require(msg.value >= amount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");
        } else {

            IERC20 _erc20 = IERC20(paymentToken);
            require( _erc20.balanceOf(_msgSender()) >= amount, "BNSCore#INSUFFICIENT_AMOUNT_VALUE");

            require(_erc20.transferFrom(_msgSender(), address(this), amount), "BNSCore#AMOUNT_TRANSFER_FAILED");
        }


    } //end 


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


}