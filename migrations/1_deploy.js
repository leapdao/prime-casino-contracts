const PrimeTester = artifacts.require('PrimeTester');
const PrimeCasino = artifacts.require('PrimeCasino');

module.exports = async (deployer) => {
  const deployVars = {
    enforcerAddr: process.env.enforcerAddr,
    minBet: process.env.minBet,
  };

  console.log(deployVars);
  for (let key in deployVars) {
    if (!deployVars[key]) {
      throw new Error(`${key} not defined via environment`);
    }
  }

  deployVars.primeTester = process.env.primeTester;
  if (!deployVars.primeTester) {
    const primeTester = await deployer.deploy(PrimeTester).await;
    deployVars.primeTester = primeTester.address;
  } else {
    console.log('Use provided primeTester: ', deployVars.primeTester);
  }

  await deployer.deploy(
    PrimeCasino,
    deployVars.enforcerAddr,
    deployVars.primeTester,
    deployVars.minBet
  );
};
