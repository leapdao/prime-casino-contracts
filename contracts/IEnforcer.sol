pragma solidity ^0.5.2;

interface IEnforcer {
  function request(bytes32 _resourceHash, bytes32 _evmParamHash) external returns (bool);
  function getStatus(bytes32 _evmParamHash) external view returns (uint256, bytes32[] memory, bytes32[] memory);
}