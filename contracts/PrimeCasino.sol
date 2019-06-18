pragma solidity ^0.5.2;

import "./IEnforcer.sol";

contract PrimeCasino {

	event NewPrime(bytes32 indexed evmParamHash, bytes32 resourceHash);

	uint256 public minBet;
	address public enforcerAddr;

	struct Sum {
		uint256 sumYes;
		uint256 sumNo;
	}

	mapping(bytes32 => mapping(address => int256)) primeBets;
	mapping(bytes32 => Sum) primeBetSums;

	constructor(address _enforcerAddr, uint256 _minBet) public {
		enforcerAddr = _enforcerAddr;
		minBet = _minBet;
	}
    
  // calling request bets on yesPrime automatically
  function request(bytes32 _resourceHash, bytes32 _evmParamHash) public payable {
  	require(msg.value >= minBet, "Not enough ether sent to pay for bet");
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	require(enforcer.request(_resourceHash, _evmParamHash), "could not register task");
  	primeBets[_evmParamHash][msg.sender] = int256(msg.value);
  	primeBetSums[_evmParamHash] = Sum({
  		sumYes: msg.value,
  		sumNo: 0
		});
		emit NewPrime(_evmParamHash, _resourceHash);
  }

  function bet(bytes32 _evmParamHash, bool _isPrime) public payable {
  	require(msg.value >= minBet, "Not enough ether sent to pay for bet");
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	uint256 endTime;
  	(endTime ,,) = enforcer.getStatus(_evmParamHash);
  	require(endTime > 0, "not a known bet");
  	require(endTime > now, "bet duration expired");
  	if (_isPrime) {
  		primeBets[_evmParamHash][msg.sender] += int256(msg.value);
  		primeBetSums[_evmParamHash].sumYes += msg.value;
  	} else {
  		primeBets[_evmParamHash][msg.sender] -= int256(msg.value);
  		primeBetSums[_evmParamHash].sumNo += msg.value;
  	}
  }

  function getStatus(bytes32 _evmParamHash) public view returns (uint256 _challengeEndTime, bytes32[] memory _pathRoots) {
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	(_challengeEndTime, _pathRoots,) = enforcer.getStatus(_evmParamHash);
  }

  function payout(bytes32 _evmParamHash) public {
  	int256 betAmount = primeBets[_evmParamHash][msg.sender];
  	require(betAmount != 0, "no bet amount");
  	uint256 endTime;
  	bytes32[] memory pathRoots;
  	bytes32[] memory results;
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	(endTime, pathRoots, results) = enforcer.getStatus(_evmParamHash);
  	require(endTime < now, "bet duration not passed");
  	uint256 payoutAmount;
  	if (pathRoots.length == 0 || pathRoots.length > 1) {
  		if (betAmount < 0) {
  			betAmount *= -1;
  		}
  		payoutAmount = uint256(betAmount);
  	} else {
	  	uint256 total = primeBetSums[_evmParamHash].sumYes + primeBetSums[_evmParamHash].sumNo;
	  	if (betAmount > 0) {
	  		require(keccak256(abi.encode(1)) == results[0], "bet prime, but not found prime");
	  		// amount * total / sameSide
	  		payoutAmount = uint256(betAmount) * total / primeBetSums[_evmParamHash].sumYes;
			} else {
				require(keccak256(abi.encode(0)) == results[0], "bet not prime, but found prime");
				betAmount *= -1;
				payoutAmount = uint256(betAmount) * total / primeBetSums[_evmParamHash].sumNo;
			}
		}
		primeBets[_evmParamHash][msg.sender] = 0;
    msg.sender.transfer(payoutAmount);
  }
}