/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;

import "../Defs.sol";

abstract contract IRegistry is Defs {

    function mintDomain(address _to, string calldata _label, SvgProps memory _svgInfo ) virtual public returns(uint256, bytes32);

    function getTLD(bytes32 node) virtual  public view returns(TLDInfo memory);
    function getRecord(bytes32 _node) virtual public view returns(Record memory);
    function ownerOf(uint256 tokenId) virtual public view returns(address);
    function controller(bytes32 node) virtual public view returns(address);

}