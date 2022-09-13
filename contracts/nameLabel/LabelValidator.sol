/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "../DataStore.sol";
import "./LabelValidatorLib.sol";

contract LabelValidator   {

    using LabelValidatorLib for string;

    /**
     * @dev matches string or not
     * @param _label the str to validate
     */
    function matches(string memory _label)
        public 
        pure 
        returns (bool)
    {
        return _label.matches();
    }

}