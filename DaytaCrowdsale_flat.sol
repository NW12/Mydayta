pragma solidity ^0.5.2;
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
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
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}








contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    uint256 _allowance = allowed[_from][msg.sender];
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
  function increaseApproval (address _spender, uint _addedValue) external
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval (address _spender, uint _subtractedValue) external
    returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0x0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply = SafeMath.sub(totalSupply, _unsoldTokens);
  }
}



contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = false;
  modifier whenNotPaused() {
    require(!paused);
    _;
  }
  modifier whenPaused() {
    require(paused);
    _;
  }
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




contract Whitelisted is Ownable {
  Whitelist.List private _list;
  modifier onlyWhitelisted() {
    require(Whitelist.check(_list, msg.sender) == true);
    _;
  }
  event AddressAdded(address beneficiary);
  event AddressRemoved(address beneficiary);

  constructor() public {
    Whitelist.add(_list, msg.sender);
  }
  function enable(address _beneficiary) external onlyOwner {
    Whitelist.add(_list, _beneficiary);
    emit AddressAdded(_beneficiary);
  }
  function disable(address _beneficiary) external {
    Whitelist.remove(_list, _beneficiary);
    emit AddressRemoved(_beneficiary);
  }
  function isListed(address _beneficiary) external view returns (bool){
    return Whitelist.check(_list, _beneficiary);
  }
}

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
  uint256 public totalSupply = SafeMath.mul(2500000000, 1 ether);
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
    minPurchase = 1;
    maxPurchase = 50;
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
    require((weiAmount >= (minPurchase * 1 ether)) && (weiAmount <= (maxPurchase * 1 ether)));
    if((accessTime >= investorStartTime) && (accessTime < investorEndTime))
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
    require(_minPurchase>0);
    minPurchase = _minPurchase;
    maxPurchase = _maxPurchase;
  }
  function transferFunds(address[] memory recipients, uint256[] memory values) onlyOwner public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function bountyFunds(address[] memory recipients, uint256[] memory values) onlyOwner public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        require(bountySupply >= values[i]);
        bountySupply = SafeMath.sub(bountySupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferPartnershipsTokens(address[] memory recipients, uint256[] memory values) onlyOwner public {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        require(partnershipsSupply >= values[i]);
        partnershipsSupply = SafeMath.sub(partnershipsSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferReserveTokens(address[] memory recipients, uint256[] memory values) onlyOwner public {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        require(reserveSupply >= values[i]);
        reserveSupply = SafeMath.sub(reserveSupply,values[i]);
        token.mint(recipients[i], values[i]);
    }
  }
  function transferTeamTokens(address[] memory recipients, uint256[] memory values) onlyOwner public {
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



contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  function hasEnded() public view returns (bool) {
      return now > ICOEndTime;
  }
}






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
  function refund(address investor) external {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    msg.sender.transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}
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
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    vault.refund(msg.sender);
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



contract Dayta is MintableToken {
  string public constant name = "DAYTA";
  string public constant symbol = "XPD";
  uint8 public constant decimals = 18;
  uint256 public _totalSupply = SafeMath.mul(2500000000 , 1 ether);
  constructor() public {
    totalSupply = _totalSupply;
  }
}

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