/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "../Defs.sol";

abstract contract IRegistry is Defs {

    function addDomain(address _to, string calldata _label) virtual public returns(uint256, bytes32);

    function getPrices() virtual public view returns (DomainPrices memory);
    function getPrice(string memory _label) virtual public view returns (uint256);
    function getRegistryInfo() virtual public view returns(RegistryInfo memory);
    function getRecord(bytes32 _node) virtual public view returns(Record memory);
}