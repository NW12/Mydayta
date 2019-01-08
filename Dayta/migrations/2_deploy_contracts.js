var DaytaCrowdsale = artifacts.require("./DaytaCrowdsale.sol");
var web3 = require('web3');

module.exports = function (deployer) {

  var _startTime = 1547510400;
  var _endTime = 1557964740;
  var _rate = 33750;
  var _cap = web3.utils.toWei('45000', 'ether');
  var _goal = web3.utils.toWei('3000', 'ether');
  var _wallet = "0xfEcB6d19b40f72672c86A6EE54979E1c0253717f";

  return deployer.deploy(DaytaCrowdsale, _startTime, _endTime, _rate, _cap, _goal, _wallet).then(async () => {
    const instance = await DaytaCrowdsale.deployed();
    const token = await instance.getTokenAddress.call();
    const vault = await instance.getVaultAddress.call();
    console.log('-----------------------------------------------');
    console.log('Info : Contract Address : ', instance.address);
    console.log('Info : Token Address    : ', token);
    console.log('Info : Vault Address    : ', vault);
    console.log('-----------------------------------------------');
    console.log('-----------------------------------------------');
    console.log("Params : start time : " + _startTime);
    console.log("Params : end time : " + _endTime);
    console.log("Params : rate : " + _rate);
    console.log("Params : cap : "+_cap);
    console.log("Params : goal : " + _goal);
    console.log("Params : wallet : " + _wallet);
    console.log('-----------------------------------------------');
  });
};