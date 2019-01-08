pragma solidity ^0.5.0;
import '../math/SafeMath.sol';
import '../ownership/Ownable.sol';
import './Crowdsale.sol';
contract FinalizableCrowdsale is Crowdsale {
  using SafeMath for uint256;
  bool isFinalized = false;
  event Finalized();
  function finalizeCrowdsale() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    finalization();
    }
  function finalization() internal {
    emit Finalized();
    isFinalized = true;
  }
}