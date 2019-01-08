pragma solidity ^0.5.0;
library Whitelist {
  struct List {
    mapping(address => bool) registry;
  }
  function add(List storage list, address beneficiary) internal {
    list.registry[beneficiary] = true;
  }
  function remove(List storage list, address beneficiary) internal {
    list.registry[beneficiary] = false;
  }
  function check(List storage list, address beneficiary) view internal returns (bool) {
    return list.registry[beneficiary];
  }
}