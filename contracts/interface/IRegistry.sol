/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "../Defs.sol";

abstract contract IRegistry is Defs {

    function mintDomain(
        address     _to,
        string      calldata       _label,
        string      calldata        _tld,
        SvgProps    memory         _svgProps
    ) virtual public returns(uint256, bytes32);
    
    function getTLD(bytes32 node) virtual  public view returns(TLDInfo memory);
    function getNode(bytes32 _node) virtual public view returns(Node memory);
    function ownerOf(uint256 tokenId) virtual public view returns(address);
    function controller(bytes32 node) virtual public view returns(address);

}