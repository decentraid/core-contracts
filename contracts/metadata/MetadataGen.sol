/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/Base64Upgradeable.sol";
import "../Defs.sol";

contract MetadataGen is Defs {

    // implementation in registry contract
    //function reverseNode(bytes32 _node) virtual public view returns(string memory);

    function getTokenURI(
        string memory _domain,
        SvgProps memory _svgProps
    )
        public
        pure 
        returns (string memory) 
    {

       string memory _image = getImage(_domain, _svgProps);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name:"', '"',_domain,'"',
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
     * @param _svgProps the svg image props
     * @return string an base64 svg image uri
     */
    function getImage(
        string memory _text,
        SvgProps memory _svgProps 
    )
        public
        pure 
        returns (string memory)
    {

        bytes memory gcolors = abi.encodePacked();

        for(uint i = 0; i < _svgProps.gcolors.length; i++){
            gcolors = abi.encodePacked(
                gcolors, 
                '<stop',
                    'offset="',     _svgProps.gcolors[i][0], '"',
                    'stop-color="', _svgProps.gcolors[i][1], '"',
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
                '.__bdn_svg_text {',
                    'font: 22px bold Sans-Serif;',
                    'fill: #000000;',
                    'text-opacity: 0.8;',
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
                        _svgProps.cords,
                    '>',
                        gcolors,
                    '</linearGradient>',
                '</defs>',
                '<rect width="100%" height="100%" fill="url(#bdn-g)" />',
                svgTextData,
            '</svg>'
         );

        return string(abi.encodePacked(
            "data:image/svg+xml;base64,", 
            Base64Upgradeable.encode(svgImageData)
        ));

    }
}