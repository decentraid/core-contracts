/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "contracts/ContractBase.sol";

abstract contract NFTMetadata is ContractBase {

    // implementation in registry contract
    function reverseNode(bytes32 _node) virtual public view returns(string memory);

    function getTokenURI(
        uint256 tokenId
    )
        internal
        view 
        returns (string memory) 
    {

        // lets get the node 
        Record memory _recordInfo = _records[_tokenIdToNodeMap[tokenId]];

       if(!recordExists(_recordInfo.namehash)){
            return ""; 
       }

       string memory _domainName = reverseNode(_recordInfo.namehash);

       string memory _image = getImage(_domainName, _svgImagesProps[_recordInfo.namehash]);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name:"', '"',_domainName,'"',
                '"description:"', '""',
                '"image:"', '"', _image,'"'
            '}' 
        );


        return string(abi.encodePacked(
            "data:application/json;base64,", 
            Base64Upgradeable.encode( abi.encodePacked(metadata) )
        ));
    }

    /**
     * @dev get the token uri image, automatically generated
     * @param _text, this is the domain name 
     * @param _svgImgProps the svg image props
     * @return string an base64 svg image uri
     */
    function getImage(
        string memory _text,
        SvgImageProps memory _svgImgProps 
    )
        internal
        pure 
        returns (string memory)
    {

        bytes memory gColors = abi.encodePacked();
        //GradientColor memory _savedColors = _svgImgProps.gradientColors;

        for(uint i = 0; i < _svgImgProps.gradientColors.length; i++){
            gColors = abi.encodePacked(
                gColors, 
                '<stop',
                    'offset="',     _svgImgProps.gradientColors[i].offset, '"',
                    'stop-color="', _svgImgProps.gradientColors[i].color, '"',
                '/>'
            );
        }

        uint256 textSize = bytes(_text).length + 1;

        string memory svgTextLen = "85%";

        if(textSize >= 35) {
           svgTextLen = "95%";
        } else if(textSize >= 10) {
            svgTextLen = "90%";
        }

        bytes memory svgTextData = abi.encodePacked(
            '<style>',
                '.__bdomains_svg_text {',
                    'font: 22px bold Sans-Serif;',
                    'fill: ', _svgImgProps.textColor ,';',
                    'text-anchor: middle;'
                    'dominant-baseline: middle',
                    'letter-spacing: 3px;',
                '}',
            '<style>',
            '<text  x="50%" y="50%" textLength="', svgTextLen, '">',
                _text,
            '</text>'
        );


        bytes memory svgImageData = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">',
                '<defs>',
                    '<linearGradient',
                        'id="bdn-g"', 
                        'gradientUnits="userSpaceOnUse"',
                        'x1="',_svgImgProps.x1,'"',
                        'y1="',_svgImgProps.y1,'"',
                        'x2="',_svgImgProps.x2,'"',
                        'y2="',_svgImgProps.y2,'"',
                    '>',
                        gColors,
                    '</linearGradient>',
                    '<rect width="100%" height="100%" fill="url(#bdn-g)" />',
                    svgTextData,
                '</defs>',
            '</svg>'
         );

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,", 
            Base64Upgradeable.encode(svgImageData)
        ));

    }
}