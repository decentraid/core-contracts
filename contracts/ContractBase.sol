/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "./DataStore.sol";

contract ContractBase is DataStore {

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    function resolver(bytes32 node) public virtual view returns (address) {
        return address(this);
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public virtual view returns (uint64) {
        return 356 days;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) public virtual view returns (bool) {
        return _records[node].owner != address(0x0);
    }

    function owner(bytes32 node) public virtual view returns (address) {
        
        address addr = _records[node].owner;

        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

}