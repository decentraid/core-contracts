/** 
* Blockchain Domains
* @website github.com/bnsprotocol
* @author Team BNS <hello@bns.gg>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

//import "../utils/NameUtils.sol";
import "../interface/IERC20P.sol";
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

    // lock to mint erc20 
    address public lockToMintTokenAddr;

    bool public isLockToMintEnabled;

    // minimum required for _5pchars price
    uint256 public lockToMintMinimumRequiredTokens;

    // lock to mint lock period
    uint256 public lockToMintLockPeriod;

    // tld => registry 
    //mapping(bytes32 => address) public registries;

    // total payment tokens 
    uint256 public totalPaymentTokens;

    mapping(uint256 => PaymentTokenDef) public paymentTokens;
    mapping(address => uint256) public paymentTokensIndexes;

    ////// End Payment Token //////////
    
    /////////// Start Lock To Mint ////////////

    uint256 public totalLockToMintEntries;

    mapping(uint256 => LockToMintInfoDef) public lockToMintDataMap;
    mapping(address => uint256[]) public lockToMintIdsByAccount;
    mapping(bytes32 => uint256[]) public lockToMintIdsByTLD;

    // domainId => lockToMintId
    mapping(uint256 => uint256) public domainIdToLockToMintEntryId;
    ///// Registered domains ////////
    
    uint256 public totalDomains;

    mapping(uint256 => RegistrarNodeInfo) public _registrarNodesData;
    
    mapping(bytes32 => uint256) public _nodeHashToIdMap;

    // tld indexes
    mapping(bytes32 => uint256[]) public domainIdsByTLD;

    mapping(address => uint256[]) public domainIdsByAccount;

    //uint256[] public domainIdsByLockToMint;
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



    struct LockToMintInfoDef {
        uint256  id;
        address  tokenAddress;
        address  owner;
        uint256  quantity;
        uint256  domainId;
        uint256  lockedAt;
        uint256  lockPeriod;
        bool     claimed;
        uint256  claimedAt;
    }

    struct ERC2612PermitDef {
        address owner;
        address spender;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
}