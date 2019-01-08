pragma solidity ^0.5.0;
import './StandardToken.sol';
contract BurnableToken is StandardToken {
    event Burn(address indexed burner, uint256 value);
    function burn(uint256 _value) public {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}