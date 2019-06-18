const { deployContract, toBN, wallets } = require('./helpers/utils');
const assertRevert = require('./helpers/assertRevert');
const PrimeCasino = artifacts.require('./PrimeCasino.sol');
const EnforcerMock = artifacts.require('./EnforcerMock.sol');
const ethers = require('ethers');

contract('PrimeCasino', () => {
  let provider = ethers.getDefaultProvider();
  const evmParamHash = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const resHash = '0x0000000000000000000000000000000000000000000000000000000000000000';
  const path = '0x1100000000000000000000000000000000000000000000000000000000000011';
  const yesHash = ethers.utils.solidityKeccak256(['bytes32'],['0x0000000000000000000000000000000000000000000000000000000000000001']);
  const noHash = ethers.utils.solidityKeccak256(['bytes32'],['0x0000000000000000000000000000000000000000000000000000000000000000']);
  const minBet = toBN('100000000000000000');
  let casino;
  let enforcer;

  it('should allow to bet and win', async () => {
    // prepare mock
    enforcer = await deployContract(EnforcerMock);
    let tx = await enforcer.setChallengeEndTime(1);
    await tx.wait();
    tx = await enforcer.addPathAndResult(path, yesHash);
    await tx.wait();

    // deploy casino
    casino = await deployContract(PrimeCasino, enforcer.address, minBet);
    // register execution and check state
    tx = await casino.request(resHash, evmParamHash, {value: minBet});
    await tx.wait();
    tx = await casino.payout(evmParamHash, { gasLimit: 0x0fffffffffffff});
    tx = await tx.wait();
  });

  it('should allow to bet and loose', async () => {
    // prepare mock
    enforcer = await deployContract(EnforcerMock);
    let tx = await enforcer.setChallengeEndTime(1);
    await tx.wait();
    tx = await enforcer.addPathAndResult(path, noHash);
    await tx.wait();

    // deploy casino
    casino = await deployContract(PrimeCasino, enforcer.address, minBet);
    // register execution and check state
    tx = await casino.request(resHash, evmParamHash, {value: minBet});
    await tx.wait();
    tx = casino.payout(evmParamHash, { gasLimit: 0x0fffffffffffff});
    await assertRevert(tx, 'revert bet prime, but not found prime');
  });
});