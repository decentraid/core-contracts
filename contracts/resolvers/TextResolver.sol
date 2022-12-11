/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/pragma solidity ^0.8.0;

import "./ResolverBase.sol";

abstract contract TextResolver is ERC165StorageUpgradeable, ResolverBase {

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

      /**
     * initialize address resolver
     */
    function __TextResolver_init() virtual internal initializer {
        
        __ERC165Storage_init_unchained();

        bytes4  TEXT_INTERFACE_ID = 0x59d1d43c;
        _registerInterface(TEXT_INTERFACE_ID);

    }

    function setText(bytes32 node, string calldata key, string calldata value) external onlyAuthorized (node) {
        _textRecords[node][key] = value;
        emit TextChanged(node, key, key);
    }

    function text(bytes32 node, string calldata key) external view returns (string memory) {
        return _textRecords[node][key];
    }

}