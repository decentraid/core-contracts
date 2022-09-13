/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.0;
import "../Defs.sol";

abstract contract IMetadataGen is Defs {
    function getImage( string memory _text, SvgImageProps memory _svgImgProps) virtual public returns(string memory);
    function getTokenURI(string memory _domain,SvgImageProps memory _svgImgInfo) virtual public pure returns (string memory);
}