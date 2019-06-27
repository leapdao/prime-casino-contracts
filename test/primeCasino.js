const { deployContract, toBN, wallets } = require('./helpers/utils');
const assertRevert = require('./helpers/assertRevert');
const PrimeCasino = artifacts.require('./PrimeCasino.sol');
const EnforcerMock = artifacts.require('./EnforcerMock.sol');
const ethers = require('ethers');

contract('PrimeCasino', () => {
  let provider = ethers.getDefaultProvider();
  const path = '0x1100000000000000000000000000000000000000000000000000000000000011';
  const yesHash = ethers.utils.solidityKeccak256(['bytes'],['0x01']);
  const noHash = ethers.utils.solidityKeccak256(['bytes'],['0x00']);
  const minBet = toBN('100000000000000000');
  let casino;
  let enforcer;

  before(async () => {
    // prepare enforcer
    enforcer = await deployContract(EnforcerMock);
    // deploy casino
    casino = await deployContract(PrimeCasino, enforcer.address, enforcer.address, minBet);    
  });

  it('should allow to request and win', async () => {
    // register execution and check state
    let tx = await casino.request(123, {value: minBet});
    tx = await tx.wait();
    const taskHash = tx.logs[1].topics[2];

    // deliver result
    tx = await enforcer.registerResult(taskHash, path, "0x01");
    await tx.wait();
    tx = await enforcer.finalizeTask(taskHash);
    await tx.wait();
    tx = await casino.payout(123, { gasLimit: 0x0fffffffffffff});
    tx = await tx.wait();
  });

  it('should allow to bet and win', async () => {
    // register execution and check state
    let tx = await casino.request(131, {value: minBet});
    tx = await tx.wait();
    const taskHash = tx.logs[1].topics[2];
    tx = await casino.bet(131, true, {value: minBet});
    tx = await tx.wait();

    // deliver result
    tx = await enforcer.registerResult(taskHash, path, "0x01");
    await tx.wait();
    tx = await enforcer.finalizeTask(taskHash);
    await tx.wait();
    tx = await casino.payout(131, { gasLimit: 0x0fffffffffffff});
    tx = await tx.wait();
  });

  it('should allow to bet and loose', async () => {
    // register execution and check state
    let tx = await casino.request(234, {value: minBet});
    tx = await tx.wait();
    const taskHash = tx.logs[1].topics[2];

    // deliver result
    tx = await enforcer.registerResult(taskHash, path, "0x00");
    await tx.wait();
    tx = await enforcer.finalizeTask(taskHash);
    await tx.wait();
    tx = casino.payout(234, { gasLimit: 0x0fffffffffffff});
    await assertRevert(tx, 'revert bet prime, but not found prime');
  });
});