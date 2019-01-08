pragma solidity ^0.5.0;

import "./token/MintableToken.sol";
contract Dayta is MintableToken {
  string public constant name = "DAYTA";
  string public constant symbol = "XPD";
  uint8 public constant decimals = 18;
  uint256 public _totalSupply = 2500000000E18;
  constructor() public {
    totalSupply = _totalSupply;
  }
}