pragma solidity ^0.5.2;

interface IPrimeCasino {
  event NewPrime(bytes32 indexed evmParamHash, bytes32 resourceHash);
  function request(bytes32 _resourceHash, bytes32 _evmParamHash) external;
  function getStatus(bytes32 _evmParamHash) external view returns (uint256 _challengeEndTime, bytes32[] memory _pathRoots);
  function checkResult(bytes32 _evmParamHash, bytes32 _result) external;
}