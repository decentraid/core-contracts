/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "./DataStore.sol";
import "./utils/NameUtils.sol";
import "./Defs.sol"; 

abstract contract ContractBase is DataStore, NameUtils {

     /**
    * @dev compare tw strings 
    * @param a the first str 
    * @param b the second str
    */   
    function strMatches(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

}