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

    function bytes32ToLiteralString(bytes32 data) 
        public
        pure
        returns (string memory result) 
    {
        bytes memory temp = new bytes(65);
        uint256 count;

        for (uint256 i = 0; i < 32; i++) {
            bytes1 currentByte = bytes1(data << (i * 8));
            
            uint8 c1 = uint8(
                bytes1((currentByte << 4) >> 4)
            );
            
            uint8 c2 = uint8(
                bytes1((currentByte >> 4))
            );
        
            if (c2 >= 0 && c2 <= 9) temp[++count] = bytes1(c2 + 48);
            else temp[++count] = bytes1(c2 + 87);
            
            if (c1 >= 0 && c1 <= 9) temp[++count] = bytes1(c1 + 48);
            else temp[++count] = bytes1(c1 + 87);
        }
        
        result = string(temp);
    }
}