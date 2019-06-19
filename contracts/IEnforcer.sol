pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

contract IEnforcer {
	struct EVMParameters {
	  // Transaction sender
	  address origin;
	  // address of the current contract / execution context
	  address target;
	  // blockHash
	  bytes32 blockHash;
	  // blockNumber
	  uint256 blockNumber;
	  // timestamp of the current block in seconds since the epoch
	  uint256 time;
	  // tx gas limit
	  uint256 txGasLimit;
	  // customEnvironmentHash - for custom implementations like Plasma Exit
	  bytes32 customEnvironmentHash;
	  // codeHash / dataHash should be the root hash of the given merkle tree
	  // Except that codeHash could also be the contract address (needs clarification)
	  bytes32 codeHash;
	  bytes32 dataHash;
	}
  function request(EVMParameters memory _params, bytes memory _data) public returns (bytes32);
  function getStatus(bytes32 _taskHash) public view returns (uint256, bytes32[] memory, bytes32[] memory);

}