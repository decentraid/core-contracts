/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "../utils/NameUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRegistry.sol";
import "../priceFeed/PriceFeed.sol";

contract RegistrarBase is 
    Defs,
    NameUtils,
    PriceFeed
{

    ////////////// Rgistries ///////////////
    // node => registry address 

    mapping(bytes32  => address) public registryInfo;
    bytes32[] public registryIds;

    mapping(bytes32 => DomainPrices) public domainPrices;
    
    //// Payment Tokens //////

    // total payment tokens 
   
    uint256 public totalPaymentTokens;

    mapping(uint256 => PaymentTokenDef) public paymentTokens;
    mapping(address => uint256) public paymentTokensIndexes;

    ////// End Payment Token //////////

    ///// Registered domains ////////
    
    uint256 public totalDomains;

    mapping(uint256 => DomainInfoDef) public domainsInfo;
    
    mapping(bytes32 => uint256) public domainIdByNode;

    // tld indexes
    mapping(bytes32 => uint256[]) public domainIdsByTLD;

    mapping(address => uint256[]) public domainIdsByAccount;

    ////////  End Registered Domains //// 

    // native asset Address 
    address public nativeAssetAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // request signer 
    address _signer;

    address public treasuryAddress;

    //check request authorization (default: true)
    bool _checkRequestAuth;

    // affiliate share 
    uint256 public affiliateSharePercent;

    // stable coin contract
    address public defaultStableCoin;

    uint256 _priceSlippageToleranceRate;

    /**
     * tld Exists 
     */
    modifier tldExists(string memory _tld) {
        require(registryInfo[getTLDNameHash(_tld)] != address(0), "BNS#tldExists: UNKNOWN_TLD");
        _;
    }

    
}