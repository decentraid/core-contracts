/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "./NameLabelRegex.sol";

contract NameUtils  {

    /**
    * only valid punnyCode label format
    */    
    modifier onlyValidLabel(string memory nameLabel) {
        require( NameLabelRegex.matches(nameLabel), "BNS#NameUtils: INVALID_LABEL_PUNNYCODE_FORMAT");
        _;
    }

    /**
     * @dev if the domain label matches the punnycode format pattern
     * @param nameLabel string variable of the name label
     */
    function isValidNameLabel(string memory nameLabel) 
        pure
        internal 
        returns(bool) 
    {
        return NameLabelRegex.matches(nameLabel);
    }

    /**
     *  @dev nameHash convert the string to name hash format
     *  @param _label string variable of the name label example bnb, cake ...
     *  @param _parentHash the parenthash 
     */
    function nameHash(string memory _label, bytes32 _parentHash)
        public 
        pure 
        returns (bytes32 _namehash) 
    {  
        require(_parentHash == "", "BNS#NameUtils: PARENT_HASH_REQUIRED");
        _namehash = keccak256(abi.encodePacked(_parentHash, keccak256(abi.encodePacked(_label))));
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

}