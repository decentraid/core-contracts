/*
* Decentra ID
* @website github.com/decentraid
* @author Decentraid Team <hello@decentraid.io>
* @license SPDX-License-Identifier: MIT
*/
pragma solidity ^0.8.0;

abstract contract ILabelValidator  {
    function matches(string memory _label) virtual public pure returns (bool);
}