/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../Defs.sol";
import "../libs/@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../libs/@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "../libs/@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

contract Uniswap is Defs {

    using SafeMathUpgradeable for uint;

    function uniswapFetchTokenPrice(
        address _pairAddress 
    ) 
        public 
        view 
        returns (uint256) 
    {
        IUniswapV2Pair v2Pair = IUniswapV2Pair(_pairAddress);
        
        (uint112 reserve0, uint112 reserve1, ) = v2Pair.getReserves();
        
        return getAmountOut(1, reserve0, reserve1);
    } //end 

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }


    /**
     * @dev get pair 
     * @param _factory the dex factory
     * @param _tokenA the first token 
     * @param _tokenB the base tokens 
     */
    function getUniswapPairToken(
        address _factory,
        address _tokenA,
        address _tokenB
    ) 
        public 
        view 
        returns(address)
    {
        return IUniswapV2Factory(_factory).getPair(_tokenA, _tokenB);
    }


    /**
     * getWeth
     */
    function getWETH(
        address _router
    )
        public 
        view 
        returns(address)
    {
        return IUniswapV2Router01(_router).WETH();
    }

}