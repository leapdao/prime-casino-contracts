const { deployContract } = require('./helpers/utils');
const Casino = artifacts.require('./PrimeCasino.sol');

contract('PrimeCasino', () => {
  const customEnvironmentHash = '0x0000000000000000000000000000000000000000000000000000000000000000';
  let casino;

  before('Prepare contracts', async () => {
    casino = await deployContract(Casino);

  });

  it('should allow to register and challenge execution', async () => {
    // register execution and check state
    let tx = await casino.getStatus(customEnvironmentHash);
    console.log(tx);
  });
});