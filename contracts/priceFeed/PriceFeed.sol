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
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "hardhat/console.sol";

contract PriceFeed is Defs, ChainLink {

    using SafeMathUpgradeable for uint256;

    /**
     * @dev get token price
     * @param _pTokenInfo the payment token Info 
     */
    function toTokenAmount(
        uint256 _amountUSD, 
        PaymentTokenDef memory _pTokenInfo,
        uint _pTokenDecimals
    )
        public 
        view 
        returns(uint256)
    {
        if(_amountUSD == 0) return 0;

        FeedInfo memory feed = getChainLinkPrice(_pTokenInfo.priceFeedContract);

        uint256 _rate = feed.rate;

       /// console.log("rrraaattteee before ============>", feed.rate);

        //convert the rate to 18th unit if the feed's decimals is not 18
        if(feed.decimals < 18){
            _rate = feed.rate *  10 ** (18 - feed.decimals);
        }


        uint256 _price = (_amountUSD * 10 ** 18) / _rate;

        ////console.log("_priceBefore============>", _price);

        //convert to the decimal of the final asset
        if(_pTokenDecimals < 18) {
            _price = _price  / 10 ** (18 - _pTokenDecimals);
        }

        /*console.log("_priceAfter============>", _price);
        console.log("rate decimals============>", feed.decimals);
        console.log("_amountUSD============>", _amountUSD);
        console.log("_pTokenDecimals============>", _pTokenDecimals);
        */
        
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