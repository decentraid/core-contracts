/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../Defs.sol";
import "./ChainLink.sol";
import "./Uniswap.sol";

contract PriceFeed is Defs, ChainLink, Uniswap {

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

        if(_pTokenInfo.priceFeedSource == stringToBytes32("chainlink")) {
            _rate = getChainLinkPrice(_pTokenInfo.priceFeedContract);
        } else {
            _rate = uniswapFetchTokenPrice(_pTokenInfo.dexPairToken);
        }

        uint256 _price = _rate.mul(_amountUSDT);

        return _price;
    } 


    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

}