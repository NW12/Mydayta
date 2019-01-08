pragma solidity ^0.5.0;
import './Claimable.sol';
contract DelayedClaimable is Claimable {
  uint256 public end;
  uint256 public start;
  function setLimits(uint256 _start, uint256 _end) onlyOwner public {
    require(_start <= _end);
    end = _end;
    start = _start;
  }
  function claimOwnership() onlyPendingOwner public {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0x0);
    end = 0;
  }
}