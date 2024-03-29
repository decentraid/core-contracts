// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LabelValidatorLib {

  struct State {
    bool accepts;
    function (bytes1) pure internal returns (State memory) func;
  }

  string public constant regex = "([a-z0-9-]+)|((xn--)([a-z0-9-]+))";

  function s0(bytes1 c) pure internal returns (State memory) {
    c = c;
    return State(false, s0);
  }

  function s1(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 119 || _cint >= 121 && _cint <= 122) {
          return State(true, s2);
        }
        if (_cint == 120) {
          return State(true, s3);
        }

    return State(false, s0);
  }

  function s2(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s4);
        }

    return State(false, s0);
  }

  function s3(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 109 || _cint >= 111 && _cint <= 122) {
          return State(true, s4);
        }
        if (_cint == 110) {
          return State(true, s5);
        }

    return State(false, s0);
  }

  function s4(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s4);
        }

    return State(false, s0);
  }

  function s5(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45) {
          return State(true, s6);
        }
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s4);
        }

    return State(false, s0);
  }

  function s6(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45) {
          return State(true, s7);
        }
        if (_cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s4);
        }

    return State(false, s0);
  }

  function s7(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s8);
        }

    return State(false, s0);
  }

  function s8(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s9);
        }

    return State(false, s0);
  }

  function s9(bytes1 c) pure internal returns (State memory) {

     uint8 _cint = uint8(c);

        if (_cint == 45 || _cint >= 48 && _cint <= 57 || _cint >= 97 && _cint <= 122) {
          return State(true, s9);
        }

    return State(false, s0);
  }

  function matches(string memory input) 
    internal 
    pure 
    returns (bool) 
  {
    State memory cur = State(false, s1);

    for (uint i = 0; i < bytes(input).length; i++) {
      bytes1 c = bytes(input)[i];

      cur = cur.func(c);
    }

    return cur.accepts;
  }
}
