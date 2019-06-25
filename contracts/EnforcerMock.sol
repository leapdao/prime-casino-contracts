pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;
import "./IEnforcer.sol";

contract EnforcerMock is IEnforcer {

  struct Task {
    uint256 challengeEndTime; // =0 not existing, =1 requested, no result, > 1 result registered 
    bytes32[] pathRoots;
    bytes32[] results;
  }

  mapping(bytes32 => Task) tasks;

  event Registered(bytes32 indexed _taskHash, bytes32 indexed _pathRoot, bytes result);

  function registerResult(bytes32 _taskHash, bytes32 _pathRoot, bytes memory result) public {
    if (tasks[_taskHash].challengeEndTime <= 1) {
      bytes32[] memory empty = new bytes32[](0);
      tasks[_taskHash] = Task({
        challengeEndTime: now + 2 hours,
        pathRoots: empty,
        results: empty
      });
    }
    tasks[_taskHash].pathRoots.push(_pathRoot);
    tasks[_taskHash].results.push(keccak256(result));
    emit Registered(_taskHash, _pathRoot, result);
  }

  function finalizeTask(bytes32 _taskHash) public {
    tasks[_taskHash].challengeEndTime = now - 1;
  }

  event Request(bytes32 indexed _taskHash, bytes _data);

  function parameterHash(EVMParameters memory _parameters) internal returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        _parameters.codeHash,
        _parameters.dataHash
      )
    );
  }
    
  function request(EVMParameters memory _params, bytes memory _data) public returns (bytes32) {
    bytes32 taskHash = parameterHash(_params);
    require(tasks[taskHash].challengeEndTime == 0, "task already requested");
    bytes32[] memory empty = new bytes32[](0);
    tasks[taskHash] = Task({
      challengeEndTime: 1,
      pathRoots: empty,
      results: empty
    });
		emit Request(taskHash, _data);
    return taskHash;
  }

  function getStatus(bytes32 _taskHash) public view returns (uint256, bytes32[] memory, bytes32[] memory) {
    Task memory task = tasks[_taskHash];
  	return(task.challengeEndTime, task.pathRoots, task.results);
  }

}