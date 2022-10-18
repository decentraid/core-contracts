/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../Defs.sol";

contract ChainLink is Defs {

    function getChainLinkPrice(address _feedContract) 
        public 
        view 
        returns (FeedInfo memory)
    {
        AggregatorV3Interface _aggrv3 = AggregatorV3Interface(_feedContract);

        (
            //uint80 roundId,
            ,
            int256 answer,
            ,,
            //uint256 startedAt,
            //uint256 updatedAt,
            //uint80 answeredInRound
        )   =   _aggrv3.latestRoundData();

        return FeedInfo({ rate: uint256(answer), decimals: _aggrv3.decimals() }); 
    }   
}