/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../Defs.sol";
import "./ChainLink.sol";

contract PriceFeed is Defs, ChainLink {

    using SafeMathUpgradeable for uint256;

    /**
     * @dev get token price
     * @param _pTokenInfo the payment token Info 
     */
    function toTokenAmount(
        uint256 _amountUSDT, 
        PaymentTokenDef memory _pTokenInfo
    )
        public 
        view 
        returns(uint256)
    {
        if(_amountUSDT == 0) return 0;

        uint256 _rate;

        _rate = getChainLinkPrice(_pTokenInfo.priceFeedContract).rate;

        uint256 _price = _rate.mul(_amountUSDT); 

        return _price;
    } 


    function toBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

}