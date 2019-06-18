pragma solidity ^0.5.2;

import "./IEnforcer.sol";

contract EnforcerMock is IEnforcer {

  uint256 challengeEndTime;
  bytes32[] pathRoots;
  bytes32[] results;

	function setChallengeEndTime(uint256 _challengeEndTime) public {
		challengeEndTime = _challengeEndTime;
	}

  function addPathAndResult(bytes32 _pathRoot, bytes32 _resultHash) public {
    pathRoots[pathRoots.length++] = _pathRoot;
    results[results.length++] = _resultHash;
  }

  event Request(bytes32 indexed evmParamHash, bytes32 resourceHash);
    
  function request(bytes32 _resourceHash, bytes32 _evmParamHash) public returns (bool) {
		emit Request(_evmParamHash, _resourceHash);
    return (pathRoots.length == 0 || pathRoots[0] != _resourceHash);
  }

  function getStatus(bytes32) public view returns (uint256, bytes32[] memory, bytes32[] memory) {
  	return(challengeEndTime, pathRoots, results);
  }

}