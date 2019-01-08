pragma solidity ^0.5.0;

import '../math/SafeMath.sol';
import '../ownership/Ownable.sol';

contract RefundVault is Ownable {
  using SafeMath for uint256;
  enum State { Active, Refunding, Closed }
  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;
  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);
  constructor(address _wallet) public {
    require(_wallet != address(0x0));
    wallet = _wallet;
    state = State.Active;
  }
  function deposit(address investor) onlyOwner external payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }
  function close() onlyOwner external {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    msg.sender.transfer(address(this).balance);
  }
  function enableRefunds() onlyOwner external {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }
  function refund() public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[msg.sender];
    deposited[msg.sender] = 0;
    msg.sender.transfer(depositedValue);
    emit Refunded(msg.sender, depositedValue);
  }
}