pragma solidity ^0.5.0;
import '../math/SafeMath.sol';
import './FinalizableCrowdsale.sol';
import './RefundVault.sol';
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;
  uint256 public goal;
  RefundVault public vault;
  constructor(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }
  function withdrawFunds(uint256 _amount) external onlyOwner {
    address(msg.sender).transfer(_amount);
  }
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    vault.refund();
  }
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  }
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
  function getVaultAddress() onlyOwner public view returns (RefundVault) {
    return vault;
  }
}