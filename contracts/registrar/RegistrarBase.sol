/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

//import "../utils/NameUtils.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interface/IRegistry.sol";
import "../priceFeed/PriceFeed.sol";
import "../interface/ILabelValidator.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract RegistrarBase is 
    Defs,
    PriceFeed
{

    // label validator 
    ILabelValidator internal _nameLabelValidator;

    ////////////// Rgistries ///////////////
    IRegistry public _registry;

    // tld => registry 
    //mapping(bytes32 => address) public registries;

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
    address public nativeAssetAddress;

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
     * only valid label
     */
    modifier onlyValidLabel(string memory nameLabel) {
        require(_nameLabelValidator.matches(nameLabel), "NameUtils#onlyValidLabel: INVALID_LABEL_PUNNYCODE_FORMAT");
        _;
    }

    /**
     *  @dev nameHash for registry TLD 
     *  @param _tld string variable of the name label example bnb, cake ...
     */
    function getTLDNameHash(string memory _tld)
        public 
        pure 
        returns (bytes32 _namehash) 
    {  
        _namehash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        _namehash = keccak256(abi.encodePacked(_namehash, keccak256(abi.encodePacked(_tld))));
    }

    /**
     * tld Exists 
     */
    modifier TLDExists(string memory _tld) {
        require(address(_registry) != address(0), "Registrar#TLDExists: REGISTRY_NOT_SET");
        require(_registry.getTLD(getTLDNameHash(_tld)).createdAt > 0, "Registrar#TLDExists: UNKNOWN_TLD");
        _;
    }

    
   

}