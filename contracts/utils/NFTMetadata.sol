/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "contracts/ContractBase.sol";

contract NFTMetadata is ContractBase {

    function getTokenURI(
         uint256 tokenId
    )
        internal
        view 
        returns (string memory) 
    {

        // lets get the node 
        Record memory _recordInfo = _records[_tokenIdToNodeMap[tokenId]];

        require(recordExists(_recordInfo.namehash), "BNS#NFTMetadata: RECORD_DOES_NOT_EXIST");

        return "";
    }

    /**
     * @dev get the token uri image, automatically generated
     * @param text, this is the domain name 
     * @param bgColors the background colors, used for linear gradient
     * @param textColor the text color can be omitted as an default is stated
     * @return string an base64 svg image uri
     */
    function getImage(
        string memory text, 
        string[] memory bgColors,
        string memory textColor
    )
        internal
        pure 
        returns (string memory)
    {

        bytes memory gColorsData = abi.encodePacked();

        for(uint i = 0; i < bgColors.length; i++){
            gColorsData = abi.encodePacked(gColorsData, '<stop offset="0%" style="stop-color:',bgColors[i],';stop-opacity:1.00" />');
        }

        if(bytes(textColor).length == 0){
            textColor = "#cfd8dc";
        }

        bytes memory svgImageData = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">',
                '<style>',
                    '.__bns-doamin {',
                        'font-size: 40px;',
                        'font-weight:660;',
                        'font-family: Courier, Verdana, Arial Black;',
                        'fill: ', textColor ,';',
                        'text-anchor: middle;'
                        'dominant-baseline: middle',
                        'textLength:',bytes(text).length+1,';',
                        'letter-spacing: 5;',
                    '}',
                '<style>',   
                '<defs>',
                    '<linearGradient id="lgrad" x1="0%" y1="50%" x2="100%" y2="50%">',
                        gColorsData,
                    '</linearGradient>',
                '</defs>',
                '<text class="__bns-doamin" x="50%" y="50%">', 
                    text,
                '</text>',
                '<rect x="0" y="0" width="100%" height="100%" fill="url(#lgrad)"/>',
            '</svg>'
        );

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,", 
            Base64Upgradeable.encode(svgImageData)
        ));
    }
}