/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "./Defs.sol";
import "./interface/IMetadataGen.sol";
import "./interface/ILabelValidator.sol";

contract DataStore is Defs {

    // self instance 
   // _IERC721Min immutable __INSTANCE = _IERC721Min(address(this));

    // icann standard
    uint constant public MAX_LABEL_LENGTH = 63;

    // max subdomain depth
    //uint constant public MAX_SUBDOMAIN_DEPTH = 3;

    RegistryInfo                        internal    _registryInfo;
    mapping(bytes32 => Record)          internal     _records;
    mapping(uint256 => bytes32)         internal     _tokenIdToNodeMap;
    mapping(address => bytes32)         internal     _reverseAddress;
    mapping(bytes32 => SvgImageProps)   internal     _svgImagesProps;
    

    // resolver addresses
    // node => address
    mapping(bytes32 => mapping( uint => bytes)) internal _addressRecords;

    // node => key => value
    mapping(bytes32 => mapping(string => string)) internal _textRecords;

    //nft metadata generator
    IMetadataGen internal _metadataGenerator;

    // label validator 
    ILabelValidator internal _nameLabelValidator;
}