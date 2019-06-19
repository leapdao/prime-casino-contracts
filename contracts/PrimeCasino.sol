pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
import "./IEnforcer.sol";

contract PrimeCasino {

	event NewPrime(uint256 indexed prime, bytes32 indexed taskHash);

	uint256 public minBet;
	address public enforcerAddr;
	address public primeTester;

	struct Sum {
		bytes32 taskHash;
		uint256 sumYes;
		uint256 sumNo;
	}

	mapping(uint256 => mapping(address => int256)) primeBets;
	mapping(uint256 => Sum) primeBetSums;

	constructor(address _enforcerAddr, address _primeTester, uint256 _minBet) public {
		enforcerAddr = _enforcerAddr;
		minBet = _minBet;
		primeTester = _primeTester;
	}
    
  // calling request bets on yesPrime automatically
  function request(uint256 _primeNumber) public payable {
  	require(msg.value >= minBet, "Not enough ether sent to pay for bet");
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	bytes memory data = abi.encodePacked(_primeNumber);
  	IEnforcer.EVMParameters memory params = IEnforcer.EVMParameters({
			origin: msg.sender,
	  	target: primeTester,
	  	blockHash: 0,
	  	blockNumber: 0,
	    time: 0,
	    txGasLimit: 0xffffffff,
	    customEnvironmentHash: 0,
	    codeHash: bytes32(bytes20(primeTester)),
	    dataHash: keccak256(data)
  	});
  	bytes32 taskHash = enforcer.request(params, data);
  	primeBets[_primeNumber][msg.sender] = int256(msg.value);
  	primeBetSums[_primeNumber] = Sum({
  		taskHash: taskHash,
  		sumYes: msg.value,
  		sumNo: 0
		});
		emit NewPrime(_primeNumber, taskHash);
  }

  function bet(uint256 _primeNumber, bool _isPrime) public payable {
  	require(msg.value >= minBet, "Not enough ether sent to pay for bet");
  	uint256 endTime;
  	bytes32 taskHash = primeBetSums[_primeNumber].taskHash;
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	(endTime ,,) = enforcer.getStatus(taskHash);
  	require(endTime > 0, "not a known bet");
  	require(endTime > now, "bet duration expired");
  	if (_isPrime) {
  		primeBets[_primeNumber][msg.sender] += int256(msg.value);
  		primeBetSums[_primeNumber].sumYes += msg.value;
  	} else {
  		primeBets[_primeNumber][msg.sender] -= int256(msg.value);
  		primeBetSums[_primeNumber].sumNo += msg.value;
  	}
  }

  function getStatus(uint256 _primeNumber) public view returns (uint256 _challengeEndTime, bytes32[] memory _pathRoots) {
  	bytes32 taskHash = primeBetSums[_primeNumber].taskHash;
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	(_challengeEndTime, _pathRoots,) = enforcer.getStatus(taskHash);
  }

  function payout(uint256 _primeNumber) public {
  	int256 betAmount = primeBets[_primeNumber][msg.sender];
  	require(betAmount != 0, "no bet amount");
  	uint256 endTime;
  	bytes32[] memory pathRoots;
  	bytes32[] memory results;
  	bytes32 taskHash = primeBetSums[_primeNumber].taskHash;
  	IEnforcer enforcer = IEnforcer(enforcerAddr);
  	(endTime, pathRoots, results) = enforcer.getStatus(taskHash);
  	require(endTime < now, "bet duration not passed");
  	uint256 payoutAmount;
  	if (pathRoots.length == 0 || pathRoots.length > 1) {
  		if (betAmount < 0) {
  			betAmount *= -1;
  		}
  		require(payoutAmount > 0, "nothing to pay out");
  		payoutAmount = uint256(betAmount);
  	} else {
	  	uint256 total = primeBetSums[_primeNumber].sumYes + primeBetSums[_primeNumber].sumNo;
	  	bytes memory result = new bytes(1);
	  	if (betAmount > 0) {
	  		result[0] = 0x01;
	  		require(keccak256(result) == results[0], "bet prime, but not found prime");
	  		// amount * total / sameSide
	  		payoutAmount = uint256(betAmount) * total / primeBetSums[_primeNumber].sumYes;
			} else {
				require(keccak256(result) == results[0], "bet not prime, but found prime");
				betAmount *= -1;
				payoutAmount = uint256(betAmount) * total / primeBetSums[_primeNumber].sumNo;
			}
		}
		require(payoutAmount > 0, "nothing to pay out");
		primeBets[_primeNumber][msg.sender] = 0;
    msg.sender.transfer(payoutAmount);
  }
}