/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

contract Defs {

    struct RegistryRecord {
        string      name;
        bytes32     nameHash;
        address     assetAddress;
        bool        canExpire;
        uint256     createdAt;
        uint256     updatedAt;
    }

}