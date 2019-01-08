pragma solidity ^0.5.0;

import '../math/SafeMath.sol';
import './Crowdsale.sol';

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }
  function validPurchase() internal returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }
  function hasEnded() public view returns (bool) {
      return now > ICOEndTime;
  }
}