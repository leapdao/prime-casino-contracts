pragma solidity ^0.5.2;

import "./IPrimeCasino.sol";

contract PrimeCasino is IPrimeCasino {
    
  function request(bytes32 _resourceHash, bytes32 _evmParamHash) public {

  }

  function getStatus(bytes32 _evmParamHash) public view returns (uint256 _challengeEndTime, bytes32[] memory _pathRoots) {

  }
  
  function checkResult(bytes32 _evmParamHash, bytes32 _result) public {


  }
}