pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
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
  uint256 totalSupply_;
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
  mapping (address => mapping (address => uint256)) internal allowed;
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  function burnTokens(uint256 _unsoldTokens) onlyOwner public returns (bool) {
    totalSupply_ = SafeMath.sub(totalSupply_, _unsoldTokens);
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
    Pause();
  }
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Crowdsale is Ownable, Pausable {
  using SafeMath for uint256;
  MintableToken private token;
  uint256 public preStartTime;
  uint256 public preEndTime;
  uint256 public ICOstartTime;
  uint256 public ICOEndTime;
  uint256 public preICOBonus;
  uint256 public firstWeekBonus;
  uint256 public secondWeekBonus;
  uint256 public thirdWeekBonus;
  uint256 public forthWeekBonus;
  uint256 public referalBonus;
  address internal wallet;
  uint256 public rate;
  uint256 public weiRaised;
  uint256 public nowTime;
  uint256 public weekOne;
  uint256 public weekTwo;
  uint256 public weekThree;
  uint256 public weekForth;
  uint256 public totalSupply = SafeMath.mul(2500000000, 1 ether);
  uint256 public publicSupply = SafeMath.mul(SafeMath.div(totalSupply,100),60);
  uint256 public preicoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),30);           
  uint256 public icoSupply = SafeMath.mul(SafeMath.div(totalSupply,100),30);
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
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    token = createTokenContract();
    preStartTime = _startTime;
    preEndTime = preStartTime + 30 days;
    ICOstartTime = preEndTime + 5 minutes;
    ICOEndTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    nowTime = now;
    preICOBonus = SafeMath.div(SafeMath.mul(rate,20),100);
    firstWeekBonus = SafeMath.div(SafeMath.mul(rate,15),100);
    secondWeekBonus = SafeMath.div(SafeMath.mul(rate,10),100);
    thirdWeekBonus = SafeMath.div(SafeMath.mul(rate,5),100);
    forthWeekBonus = SafeMath.div(SafeMath.mul(rate,1),100);
    referalBonus  = 100;
    weekOne = SafeMath.add(ICOstartTime, 21 days);
    weekTwo = SafeMath.add(weekOne, 21 days);
    weekThree = SafeMath.add(weekTwo, 21 days);
    weekForth = SafeMath.add(weekThree, 21 days);
    teamTimeLock = SafeMath.add(ICOEndTime, 180 days);
    reserveTimeLock = SafeMath.add(ICOEndTime, 180 days);
    partnershipsTimeLock = SafeMath.add(preStartTime, 3 minutes);
    checkBurnTokens = false;
    upgradeICOSupply = false;
  }
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
  function () public payable {
    buyTokens(msg.sender);
  }
  function buyTokens(address beneficiary) whenNotPaused public payable {
    require(beneficiary != 0x0);
    require(validPurchase());
    uint256 weiAmount = msg.value;
    uint256 accessTime = now;
    uint256 tokens = 0;
    require((weiAmount >= (1 * 1 ether)) && (weiAmount <= (50 * 1 ether)));
    if ((accessTime >= preStartTime) && (accessTime < preEndTime)) 
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
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= preStartTime && now <= ICOEndTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
  function hasEnded() public constant returns (bool) {
      return now > ICOEndTime;
  }
  function burnToken() onlyOwner  public returns (bool) {
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
  function transferFunds(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(publicSupply >= values[i]);
        publicSupply = SafeMath.sub(publicSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  } 
  function bountyFunds(address[] recipients, uint256[] values) onlyOwner  public {
     require(!checkBurnTokens);
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(bountySupply >= values[i]);
        bountySupply = SafeMath.sub(bountySupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferPartnershipsTokens(address[] recipients, uint256[] values) onlyOwner  public {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(partnershipsSupply >= values[i]);
        partnershipsSupply = SafeMath.sub(partnershipsSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferReserveTokens(address[] recipients, uint256[] values) onlyOwner  public {
    require(!checkBurnTokens);
    require((reserveTimeLock < now));
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(reserveSupply >= values[i]);
        reserveSupply = SafeMath.sub(reserveSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function transferTeamTokens(address[] recipients, uint256[] values) onlyOwner  public {
    require(!checkBurnTokens);
    require((now > teamTimeLock));
     for (uint256 i = 0; i < recipients.length; i++) {
        values[i] = SafeMath.mul(values[i], 1 ether);
        require(teamSupply >= values[i]);
        teamSupply = SafeMath.sub(teamSupply,values[i]);
        token.mint(recipients[i], values[i]); 
    }
  }
  function getTokenAddress() onlyOwner public returns (address) {
    return token;
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
    Finalized();
    isFinalized = true;
    }
  function finalization() internal {
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
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }
  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }
  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;
  uint256 public goal;
  RefundVault public vault;
  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    vault.refund(msg.sender);
  }
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }
    super.finalization();
  }
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }
}




contract Dayta is MintableToken {
  string public constant name = "DAYTA";
  string public constant symbol = "XPD";
  uint8 public constant decimals = 18;
  uint256 public totalSupply = SafeMath.mul(2500000000 , 1 ether);
  function Dayta() public { 
    totalSupply_ = totalSupply;
  }
}

contract DaytaCrowdsale is Crowdsale, RefundableCrowdsale {
    uint256 _startTime = 1547510400;
    uint256 _endTime = 1557964740;
    uint256 _rate = 33750;
    uint256 _goal = 3000 * 1 ether;
    address _wallet = 0xfEcB6d19b40f72672c86A6EE54979E1c0253717f;
    function DaytaCrowdsale () public
    FinalizableCrowdsale() 
    RefundableCrowdsale(_goal) 
    Crowdsale(_startTime,_endTime,_rate,_wallet)
    {
    }
    function createTokenContract() internal returns (MintableToken) {
        return new Dayta();
    }
}