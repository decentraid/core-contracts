/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "./Defs.sol";
import "./interface/IMetadataGen.sol";
import "./interface/ILabelValidator.sol";
import "./interface/IResolver.sol";

contract DataStore is Defs {

    // counter
    uint256 public totalTokenIds;

   //tld
    // total tlds 
    uint256   public totalTLDs;

    mapping(uint256 => TLDInfo)         public       _tlds;
    mapping(bytes32 => uint256)         internal     _tldsIds;

    // tokenId   => record
    mapping(uint256 => Node)          internal        _nodes;
    mapping(bytes32 => uint256)         internal      _recordsNodeToId;
    mapping(bytes32 => uint256[])       internal      _nodesByParent;

    //mapping(uint256 => bytes32)         internal      _tokenIdToNodeMap;
    //mapping(bytes32 => SvgProps)         public        _svgImagesProps;
     
    // namehash => address
    mapping(bytes32 => address)         internal       _controllers;


    //nft metadata generator
    IMetadataGen internal _metadataGenerator;

    // label validator 
    ILabelValidator internal _nameLabelValidator;

    // collection Uri 
    string internal _collectionUri;

    IResolver internal _resolver;
}