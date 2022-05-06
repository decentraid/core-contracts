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
     * only valid punnyCode label format
     */    
    modifier onlyValidLabel(string memory nameLabel) {
        require( NameLabelRegex.matches(nameLabel), "BNS#NameUtils: INVALID_LABEL_PUNNYCODE_FORMAT");
        _;
    }

}