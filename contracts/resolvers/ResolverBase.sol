/** 
* Blockchain Domains
* @website github.com/bdomains
* @author BDN Team <hello@bdomains.org>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

//import "../ContractBase.sol";
import "../interface/IRegistry.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

abstract contract ResolverBase is 
    MulticallUpgradeable 
{

    IRegistry public _registry;

    // resolver addresses
    // node => address
    mapping(bytes32 => mapping( uint => bytes)) internal _addressRecords;

    // node => key => value
    mapping(bytes32 => mapping(string => string)) internal _textRecords;

     /**
     * @dev is authourized
     */
    function isAuthorised(bytes32 node) internal  view returns(bool){

        require(address(_registry) != address(0), "Resolver#ResolverBase: registry address not set");
        
        address _owner = _registry.ownerOf(_registry.getNode(node).tokenId);

        if(_owner == address(0)) return false;

        if(_owner == msg.sender || _registry.controller(node) == msg.sender) return true;

        return false;
    }


    modifier onlyAuthorized(bytes32 node) {
        require(isAuthorised(node), "Resolver#ResolverBase: NOT_AUTHORISED");
        _;
    }

    /**
    * @dev compare tw strings 
    * @param a the first str 
    * @param b the second str
    */   
    function strMatches(string memory a, string memory b) public pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function bytesToAddress(bytes memory b) internal pure returns (address payable) {
        return payable(address(uint160(bytes20(b))));
    }

    function addressToBytes(address a) internal pure returns (bytes memory){
        return abi.encodePacked(a);
    }

}  

