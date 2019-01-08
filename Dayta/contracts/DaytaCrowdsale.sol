pragma solidity ^0.5.0;

import "./crowdsale/Crowdsale.sol";
import './crowdsale/CappedCrowdsale.sol';
import "./crowdsale/RefundableCrowdsale.sol";
import "./Dayta.sol";

contract DaytaCrowdsale is Crowdsale, CappedCrowdsale , RefundableCrowdsale {
    constructor(uint256 _startTime, uint256 _endTime, uint256 _rate,uint256 _cap, uint256 _goal, address _wallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
    }
    function createTokenContract() internal returns (MintableToken) {
        return new Dayta();
    }
}