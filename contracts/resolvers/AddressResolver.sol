/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "./ResolverBase.sol";

abstract contract AddressResolver is ResolverBase {

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    bytes4 constant private ADDR_INTERFACE_ID   = 0x3b3b57de;
    bytes4 constant private ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint constant private   ASSET_TYPE_ETH = 60;

    /**
     * initialize address resolver
     */
    function __AddressResolver_init() virtual internal initializer {
        __ResolverBase_init();
        _registerInterface(ADDR_INTERFACE_ID);
        _registerInterface(ADDRESS_INTERFACE_ID);
    }

  /**
     * Sets the ethereum address for BNS
     * May only be called by the owner of that node in the BNS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external onlyAuthorized(node) {
        setAddr(node, ASSET_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Returns the ethereum address associated with the node
     * @param node The BNS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, ASSET_TYPE_ETH);
        if(a.length == 0) {
            return payable(address(0));
        }
        return bytesToAddress(a);
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) public onlyAuthorized(node) {
        emit AddressChanged(node, coinType, a);
        if(coinType == ASSET_TYPE_ETH) {
            emit AddrChanged(node, bytesToAddress(a));
        }
        _addressRecords[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) public view returns(bytes memory) {
        return _addressRecords[node][coinType];
    }
}