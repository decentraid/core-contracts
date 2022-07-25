/** 
* Binance Name Service
* @website github.com/binance-name
* @author Team BNS <hello@binance.name>
* @license SPDX-License-Identifier: MIT
*/ 
pragma solidity ^0.8.0;

import "./DataStore.sol";
import "./utils/NameUtils.sol";
import "./Defs.sol";

contract ContractBase is DataStore, NameUtils {

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }

    /**
     * @dev returns the resolver 
     * @param node to return the resolver
     * @return address of the resolver 
     */
    function resolver(bytes32 node) public virtual view returns (address) {
        return address(this);
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public virtual view returns (uint64) {
        return 356 days;
    }

    /**
     * @dev generate a subdomain token id borrowed from unstoppable domain
     * @param _tokenId the main domain token id
     * @param _label the label to generate token id for 
     * @return uint256 of the subdomain token Id
     */
    function subdomainTokenId(
        uint256 _tokenId,
        string memory _label
    ) 
        public 
        view 
        onlyValidLabel(_label) 
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(_tokenId, keccak256(abi.encodePacked(_label)))));
    }


    /**
     * @dev get the domain node from a subnode 
     * @param node the node to get its domain's node
     * @return bytes32 of the domain node
     */
    function getDomainNode(bytes32 node) 
        public
        view 
        returns(bytes32) 
    {
        if(_records[node].nodeType == NodeType.DOMAIN) {
            return _records[node].namehash;
        }

        return  _records[node].primaryNode;
    }

    /**
     * @dev get the owner of a node, note that subnodes or subdomains will always belong to the nft owner for security sake
     * @param node the node to get the owner 
     * @return the owner's address of the node
     */
    function owner(
        bytes32 node
    ) 
        public 
        virtual 
        view 
        returns (address) 
    {
        
        if(node == _registryInfo.namehash){
            return address(0x0);
        }

        bytes32 parentNode = getDomainNode(node);

        return __INSTANCE.ownerOf(parentNode.tokenId);
    }


    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) 
        public 
        view 
        returns (bool) 
    {
        return _records[node].namehash != bytes32(0);
    }
    
}