pragma solidity ^0.5.2;

import "./IEnforcer.sol";

contract EnforcerMock is IEnforcer {

  struct Task {
    uint256 challengeEndTime;
    bytes32[] pathRoots;
    bytes32[] results;
  }

  mapping(bytes32 => Task) tasks;

  function registerResult(bytes32 _taskHash, bytes32 _pathRoot, bytes32 _resultHash) public {
    if (tasks[_taskHash].challengeEndTime == 0) {
      bytes32[] memory empty = new bytes32[](0);
      tasks[_taskHash] = Task({
        challengeEndTime: now + 2 hours,
        pathRoots: empty,
        results: empty
      });
    }
    tasks[_taskHash].pathRoots.push(_pathRoot);
    tasks[_taskHash].results.push(_resultHash);
  }

  function finalizeTask(bytes32 _taskHash) public {
    tasks[_taskHash].challengeEndTime = now - 1;
  }

  event Request(bytes32 indexed _taskHash, bytes32 resourceHash);
    
  function request(bytes32 _resourceHash, bytes32 _taskHash) public returns (bool) {
		emit Request(_taskHash, _resourceHash);
    return (tasks[_taskHash].pathRoots.length == 0 || tasks[_taskHash].pathRoots[0] != _resourceHash);
  }

  function getStatus(bytes32 _taskHash) public view returns (uint256, bytes32[] memory, bytes32[] memory) {
    Task memory task = tasks[_taskHash];
  	return(task.challengeEndTime, task.pathRoots, task.results);
  }

}