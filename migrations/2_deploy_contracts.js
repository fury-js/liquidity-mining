const LiqudityPool = artifacts.require('LiquidityPool')
const UnderlyingToken = artifacts.require('UnderlyingToken');
const GovernanceToken = artifacts.require('GovernanceToken');


module.exports = async function (deployer, network, accounts) {
//   deploy underlying token
    await deployer.deploy(UnderlyingToken);
    const underlyingToken = await UnderlyingToken.deployed();

    //  deploy governance token
    await deployer.deploy(GovernanceToken);
    const governanceToken = await GovernanceToken.deployed()

    // deploy liquidity pool
    await deployer.deploy(LiqudityPool, underlyingToken.address, governanceToken.address);
    const liqudityPool = await LiqudityPool.deployed()

    // transfer all tokens to token farm
    await governanceToken.transfer(LiqudityPool.address, "1000000000000000000000000");

    // transfer 100 underlying tokens to investor
    await underlyingToken.transfer(accounts[1], '100000000000000000000');
};