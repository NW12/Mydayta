pragma solidity ^0.5.0;

import '../token/MintableToken.sol';
import '../math/SafeMath.sol';
import "../lifecycle/Pausable.sol";
import "../whitelist/whitelisted.sol";

contract Crowdsale is Ownable, Pausable, Whitelisted {
  using SafeMath for uint256;
  MintableToken public token;
  uint256 public minPurchase;
  uint256 public maxPurchase;
  uint256 public investorStartTime;
  uint256 public investorEndTime;
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  uint256 public preICOBonus;
  uint256 public firstWeekBonus;
  uint256 public secondWeekBonus;
  uint256 public thirdWeekBonus;
  uint256 public forthWeekBonus;
  uint256 public flashSaleStartTime;
  uint256 public flashSaleEndTime;
  uint256 public flashSaleBonus;
  address internal wallet;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public weekOne;
  uint256 public weekTwo;
  uint256 public weekThree;
  uint256 public weekForth;
  uint256 public totalSupply = 2500000000E18;
  uint256 public preicoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),30);
  uint256 public icoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),30);
  uint256 public publicSupply = SafeMath.add(preicoSupply,icoSupply);
  uint256 public bountySupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  uint256 public teamSupply = SafeMath.mul(SafeMath.div(totalSupply,100),20);
  uint256 public reserveSupply = SafeMath.mul(SafeMath.div(totalSupply,100),5);
  uint256 public partnershipsSupply = SafeMath.mul(SafeMath.div(totalSupply,100),10);
  uint256 public teamTimeLock;
  uint256 public partnershipsTimeLock;
  uint256 public reserveTimeLock;
  bool public checkBurnTokens;
  bool public upgradeICOSupply;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  constructor(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0x0));
    token = createTokenContract();
    investorStartTime = 0;
    investorEndTime = 0;
    preStartTime = _startTime;
    preEndTime = preStartTime + 30 days;
    ICOstartTime = preEndTime + 5 minutes;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    preICOBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,1),100);
    weekOne = SafeMath.add(ICOstartTime, 21 days);
    weekTwo = SafeMath.add(weekOne, 21 days);
    weekThree = SafeMath.add(weekTwo, 21 days);
    weekForth = SafeMath.add(weekThree, 21 days);
    teamTimeLock = SafeMath.add(ICOEndTime, 180 days);
    reserveTimeLock = SafeMath.add(ICOEndTime, 180 days);
    partnershipsTimeLock = SafeMath.add(preStartTime, 3 minutes);
    flashSaleStartTime = 0;
    flashSaleEndTime = 0;
    flashSaleBonus = 0;
    checkBurnTokens = false;
    upgradeICOSupply = false;
    minPurchase = 1 ether;
    maxPurchase = 50 ether;
  }
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  function () external payable {
    buyTokens(msg.sender);
  }
  function buyTokens(address beneficiary) whenNotPaused onlyWhitelisted  public payable {
    require(beneficiary != address(0x0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
    uint256 accessTime = now;
    uint256 tokens = 0;
    require((weiAmount >= (minPurchase)) && (weiAmount <= (maxPurchase)));
    if((accessTime >= investorStartTime) && (accessTime < investorEndTime) && (accessTime < preStartTime))
    {
      tokens = SafeMath.add(tokens, weiAmount.mul(rate));
      icoSupply = icoSupply.sub(tokens);
      publicSupply = publicSupply.sub(tokens);
    }
    else if((accessTime >= flashSaleStartTime) && (accessTime < flashSaleEndTime))
    {
      tokens = SafeMath.add(tokens, weiAmount.mul(flashSaleBonus));
      tokens = SafeMath.add(tokens, weiAmount.mul(rate));
      icoSupply = icoSupply.sub(tokens);
      publicSupply = publicSupply.sub(tokens);
    }
    else if ((accessTime >= preStartTime) && (accessTime < preEndTime))
    {
        require(preicoSupply > 0);
        tokens = SafeMath.add(tokens, weiAmount.mul(preICOBonus));
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        require(preicoSupply >= tokens);
        preicoSupply = preicoSupply.sub(tokens);
        publicSupply = publicSupply.sub(tokens);
    }
    else if ((accessTime >= ICOstartTime) && (accessTime <= ICOEndTime))
    {
        if (!upgradeICOSupply)
        {
          icoSupply = SafeMath.add(icoSupply,preicoSupply);
          upgradeICOSupply = true;
        }
        if (accessTime <= weekOne)
        {
          tokens = SafeMath.add(tokens, weiAmount.mul(firstWeekBonus));
        }
        else if (( accessTime <= weekTwo ) && (accessTime > weekOne))
        {
          tokens = SafeMath.add(tokens, weiAmount.mul(secondWeekBonus));
        }
        else if (( accessTime <= weekThree ) && (accessTime > weekTwo))
        {
          tokens = SafeMath.add(tokens, weiAmount.mul(thirdWeekBonus));
        }
        else if (( accessTime <= weekForth ) && (accessTime > weekThree))
        {
          tokens = SafeMath.add(tokens, weiAmount.mul(forthWeekBonus));
        }
        tokens = SafeMath.add(tokens, weiAmount.mul(rate));
        icoSupply = icoSupply.sub(tokens);
        publicSupply = publicSupply.sub(tokens);
    }
    else if ((accessTime > preEndTime) && (accessTime < ICOstartTime))
    {
      revert();
    }
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  function hasEnded() public view returns (bool) {
      return now > ICOEndTime;
  }
  function burnToken() onlyOwner external returns (bool) {
    require(hasEnded());
    require(!checkBurnTokens);
    token.burnTokens(icoSupply);
    totalSupply = SafeMath.sub(totalSupply, publicSupply);
    preicoSupply = 0;
    icoSupply = 0;
    publicSupply = 0;
    checkBurnTokens = true;
    return true;
  }
  function updateDates(uint256 _preStartTime,uint256 _preEndTime,uint256 _ICOstartTime,uint256 _ICOEndTime) onlyOwner external {
    if(now < _preStartTime && preStartTime > now)
    {
      preStartTime = _preStartTime;
    }
    if(_preEndTime > preStartTime)
    {
      preEndTime = _preEndTime;
    }
    ICOstartTime = _ICOstartTime;
    ICOEndTime = _ICOEndTime;
    weekOne = SafeMath.add(ICOstartTime, 21 days);
    weekTwo = SafeMath.add(weekOne, 21 days);
    weekThree = SafeMath.add(weekTwo, 21 days);
    weekForth = SafeMath.add(weekThree, 21 days);
    teamTimeLock = SafeMath.add(ICOEndTime, 180 days);
    reserveTimeLock = SafeMath.add(ICOEndTime, 180 days);
    partnershipsTimeLock = SafeMath.add(preStartTime, 3 minutes);
  }
  function flashSale(uint256 _flashSaleStartTime,uint256 _flashSaleEndTime,uint256 _flashSaleBonus) onlyOwner external {
    flashSaleStartTime = _flashSaleStartTime;
    flashSaleEndTime = _flashSaleEndTime;
    flashSaleBonus = _flashSaleBonus;
  }
  function updateInvestorDates(uint256 _investorStartTime,uint256 _investorEndTime) onlyOwner external {
    investorStartTime = _investorStartTime;
    investorEndTime = _investorEndTime;
  }
  function updateMinMaxInvestment(uint256 _minPurchase,uint256 _maxPurchase) onlyOwner external {
    require(_maxPurchase > _minPurchase);
    require(_minPurchase > 0);
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
  }
  function transferFunds(address[] calldata recipients, uint256[] calldata values) onlyOwner external {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function bountyFunds(address[] calldata recipients, uint256[] calldata values) onlyOwner external {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        require(bountySupply >= values[i]);
        bountySupply = SafeMath.sub(bountySupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferPartnershipsTokens(address[] calldata recipients, uint256[] calldata values) onlyOwner external {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        require(partnershipsSupply >= values[i]);
        partnershipsSupply = SafeMath.sub(partnershipsSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferReserveTokens(address[] calldata recipients, uint256[] calldata values) onlyOwner external {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        require(reserveSupply >= values[i]);
        reserveSupply = SafeMath.sub(reserveSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferTeamTokens(address[] calldata recipients, uint256[] calldata values) onlyOwner external {
    require(!checkBurnTokens);
    require((now > teamTimeLock));
     for (uint256 i = 0; i < recipients.length; i++) {
        require(teamSupply >= values[i]);
        teamSupply = SafeMath.sub(teamSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function getTokenAddress() onlyOwner public view returns (address) {
    return address(token);
  }
}