pragma solidity ^0.5.0;
import './Whitelist.sol';
import '../ownership/Ownable.sol';

contract Whitelisted is Ownable {
  Whitelist.List private _list;
  modifier onlyWhitelisted() {
    require(Whitelist.check(_list, msg.sender) == true);
    _;
  }
  event AddressAdded(address[] beneficiary);
  event AddressRemoved(address[] beneficiary);

  constructor() public {
    Whitelist.add(_list, msg.sender);
  }
  function enable(address[] calldata _beneficiary) external onlyOwner {
    for (uint256 i = 0; i < _beneficiary.length; i++) {
      Whitelist.add(_list, _beneficiary[i]);
    }
    emit AddressAdded(_beneficiary);
  }
  function disable(address[] calldata _beneficiary) external onlyOwner {
    for (uint256 i = 0; i < _beneficiary.length; i++) {
      Whitelist.remove(_list, _beneficiary[i]);
    }
    emit AddressRemoved(_beneficiary);
  }
  function isListed(address _beneficiary) external view returns (bool){
    return Whitelist.check(_list, _beneficiary);
  }
}