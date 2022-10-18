/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

interface IResolver {
    
    function addr(bytes32 node) external view returns (address payable);
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
    function setAddr(bytes32 node, uint coinType, bytes memory a) external;
    function setAddr(bytes32 node, address a) external;

    function setText(bytes32 node, string calldata key, string calldata value) external;
    function text(bytes32 node, string calldata key) external view returns (string memory);
}