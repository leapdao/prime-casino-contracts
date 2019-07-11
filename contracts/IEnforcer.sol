pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;

contract IEnforcer {
  /// @notice Structure for the V-Game EVM environment.
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
    // Except that codeHash could also be the contract address (addr + right-padded with zeros to 32 bytes)
    bytes32 codeHash;
    bytes32 dataHash;
  }

  event Requested(bytes32 taskHash, EVMParameters parameters, bytes callData);

  event Registered(
    bytes32 indexed taskHash,
    bytes32 indexed solverPathRoot,
    uint256 executionDepth,
    bytes result
  );

  /// @notice request a new task
  /// @dev if `_parameters.dataHash` is zero and `callData.length` over zero
  /// then `_parameters.dataHash` will be recalculated
  /// @return bytes32 taskHash
  function request(EVMParameters memory _parameters, bytes memory callData) public returns (bytes32);

  /// @notice check execution results and `taskPeriod`
  /// @return endTime, pathRoots, resultHashes
  function getStatus(bytes32 _taskHash) public view returns (uint256, bytes32[] memory, bytes32[] memory);
}
