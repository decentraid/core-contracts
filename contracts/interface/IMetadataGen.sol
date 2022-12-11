/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;
import "../Defs.sol";

abstract contract IMetadataGen is Defs {
    function getImage( string memory _text, SvgProps memory _svgProps) virtual public returns(string memory);
    function getTokenURI(string memory _domain,SvgProps memory _svgInfo) virtual public pure returns (string memory);
}