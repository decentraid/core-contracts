/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract ZMultiCall   {
    
  struct CallParam {
    address target;
    bytes   data;
  }

  struct Result {
    bool success;
    bytes returnData;
  }

  function multicallStatic(CallParam[] memory callsParams) 
    public 
    view
    returns (uint256 blockNumber, bytes[] memory returnData) 
  {
    
    blockNumber = block.number;
    returnData = new bytes[](callsParams.length);
    
    for(uint256 i = 0; i < callsParams.length; i++) {
      
      (
        bool success, 
        bytes memory ret
      ) = callsParams[i].target.staticcall(callsParams[i].data);

      require(success, "Multicall#multicalStatic: call failed");

      returnData[i] = ret;
    } //end loop

  } // end fun

}
