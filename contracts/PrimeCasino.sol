pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
import "./IEnforcer.sol";

contract PrimeCasino {

  event NewCandidatePrime(uint256 indexed number, bytes32 indexed taskHash, uint256 sumYes, uint256 sumNo);
  event NewBet(uint256 indexed number, bytes32 indexed taskHash, uint256 sumYes, uint256 sumNo);
  event Payout(uint256 indexed number, address receiver, uint256 amount);

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

  function getBet(uint256 _candidate, address _bettor) public view returns (int256) {
    return primeBets[_candidate][_bettor];
  }
    
  /**
   * @dev request a new `canditateNumber` to be checked for primality.
   *
   * Emits an `NewCandidatePrime` event indicating the registration for computation.
   *
   * Requirements:
   *
   * - `msg.value` has to be at least `minBet`.
   * - `canditateNumber` should not have been registered before.
   */
  function request(uint256 _candidateNumber) public payable {
    require(msg.value >= minBet, "Not enough ether sent to pay for bet");
    IEnforcer enforcer = IEnforcer(enforcerAddr);
    bytes4 sig = 0x686109bb;
    bytes memory data = abi.encodePacked(sig, _candidateNumber, blockhash(block.number - 1));
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
    primeBets[_candidateNumber][msg.sender] = int256(msg.value);
    primeBetSums[_candidateNumber] = Sum({
      taskHash: taskHash,
      sumYes: msg.value,
      sumNo: 0
    });
    emit NewCandidatePrime(_candidateNumber, taskHash, msg.value, 0);
  }

  /**
   * @dev adds a new yes/no bet as `isPrime` on `canditateNumber`.
   *
   * Emits an `NewBet` event indicating the registration of the bet.
   *
   * Requirements:
   *
   * - `msg.value` has to be at least `minBet`.
   * - `canditateNumber` should have been registered before.
   * - `canditateNumber` should not have passed challengeEndTime yet.
   */
  function bet(uint256 _candidateNumber, bool _isPrime) public payable {
    require(msg.value >= minBet, "Not enough ether sent to pay for bet");
    uint256 endTime;
    bytes32 taskHash = primeBetSums[_candidateNumber].taskHash;
    IEnforcer enforcer = IEnforcer(enforcerAddr);
    (endTime ,,) = enforcer.getStatus(taskHash);
    require(endTime > 0, "not a known bet");
    require(endTime == 1 || endTime > now, "bet duration expired");
    Sum memory sum = primeBetSums[_candidateNumber];
    if (_isPrime) {
      primeBets[_candidateNumber][msg.sender] += int256(msg.value);
      sum.sumYes += msg.value;
    } else {
      primeBets[_candidateNumber][msg.sender] -= int256(msg.value);
      sum.sumNo += msg.value;
    }
    emit NewBet(_candidateNumber, taskHash, sum.sumYes, sum.sumNo);
  }

  /**
   * @dev Returns the status for a given `candidateNumber` that is a potentially prime.
   *
   * the return values should be interpreted like this:
   * 
   * |                       | challengeEndTime > now                                             | challengeEndTime <= now && challengeEndTime > 0                       | challengeEndTime == 0 |
   * |-----------------------|--------------------------------------------------------------------|-----------------------------------------------------------------------|-----------------------|
   * | pathRoots.length == 0 | no computation result registered yet. initial state after request. | computation market could not deliver any solution to given task.      | not requested         |
   * | pathRoots.length == 1 | first result registered. open for challenges.                      | exactly 1 result found. result can be used.                           | not requested         |
   * | pathRoots.length > 1  | some existing result challenged. cDance in progress.               | more than one result survived the cDance, computation market failed.  | not requested         |
   *
   */
  function getStatus(uint256 _candidateNumber) public view returns (uint256 _challengeEndTime, bytes32[] memory _pathRoots) {
    Sum memory sum = primeBetSums[_candidateNumber];
    if (sum.sumYes == 0 && sum.sumNo == 0) {
      // this number has not been requested yet
      return (_challengeEndTime, _pathRoots);
    }
    bytes32 taskHash = sum.taskHash;
    IEnforcer enforcer = IEnforcer(enforcerAddr);
    (_challengeEndTime, _pathRoots,) = enforcer.getStatus(taskHash);
  }

  /**
   * @dev pays out `msg.sender` on `canditateNumber`.
   *
   * Requirements:
   *
   * - `msg.sender` should have bet on this number before.
   * - `canditateNumber` should have passed challengeEndTime.
   */
  function payout(uint256 _candidateNumber) public {
    int256 betAmount = primeBets[_candidateNumber][msg.sender];
    require(betAmount != 0, "no bet amount");
    uint256 endTime;
    bytes32[] memory pathRoots;
    bytes32[] memory results;
    bytes32 taskHash = primeBetSums[_candidateNumber].taskHash;
    IEnforcer enforcer = IEnforcer(enforcerAddr);
    (endTime, pathRoots, results) = enforcer.getStatus(taskHash);
    require(endTime < now, "bet duration not passed");
    uint256 payoutAmount;
    if (pathRoots.length == 0 || pathRoots.length > 1) {
      if (betAmount < 0) {
        betAmount *= -1;
      }
      payoutAmount = uint256(betAmount);
    } else {
      uint256 total = primeBetSums[_candidateNumber].sumYes + primeBetSums[_candidateNumber].sumNo;
      bytes memory result = new bytes(1);
      if (betAmount > 0) {
        result[0] = 0x01;
        require(keccak256(result) == results[0], "bet prime, but not found prime");
        // amount * total / sameSide
        payoutAmount = uint256(betAmount) * total / primeBetSums[_candidateNumber].sumYes;
      } else {
        require(keccak256(result) == results[0], "bet not prime, but found prime");
        betAmount *= -1;
        payoutAmount = uint256(betAmount) * total / primeBetSums[_candidateNumber].sumNo;
      }
    }
    primeBets[_candidateNumber][msg.sender] = 0;
    if (payoutAmount > 0) {
      msg.sender.transfer(payoutAmount);
    }
    emit Payout(_candidateNumber, msg.sender, payoutAmount);
  }
}