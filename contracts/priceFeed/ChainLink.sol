/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChainLink  {

    function getChainLinkPrice(address _feedContract) 
        public 
        view 
        returns (uint256)
    {
        (
            //uint80 roundId,
            ,
            int256 answer,
            ,,
            //uint256 startedAt,
            //uint256 updatedAt,
            //uint80 answeredInRound
        )   =   AggregatorV3Interface(_feedContract).latestRoundData();

        return uint256(answer);
    }   
}