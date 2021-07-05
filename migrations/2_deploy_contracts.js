const LiqudityPool = artifacts.require('LiquidityPool')
const UnderlyingToken = artifacts.require('UnderlyingToken');
const GovernanceToken = artifacts.require('GovernanceToken');
const CakeStakingPool = artifacts.require('CakeStakingPool');
const CakeToken = artifacts.require('MockCakeToken');
const CAKE_MASTER_CHEF = '0x73feaa1eE314F8c655E354234017bE2193C9E24E';
const PANCAKE_ROUTER = '0x10ED43C718714eb63d5aA57B78B54704E256024E';


module.exports = async function (deployer, network, accounts) {
//   deploy underlying token
    await deployer.deploy(UnderlyingToken);
    const underlyingToken = await UnderlyingToken.deployed();

    //  deploy governance token
    await deployer.deploy(GovernanceToken);
    const governanceToken = await GovernanceToken.deployed()

    // deploy cake token
    await deployer.deploy(CakeToken);
    const cakeToken = await CakeToken.deployed()

    // deploy liquidity pool
    await deployer.deploy(LiqudityPool, underlyingToken.address, governanceToken.address);
    const liqudityPool = await LiqudityPool.deployed()

    // transfer all tokens to token farm
    await governanceToken.transfer(LiqudityPool.address, "1000000000000000000000000");

      // transfer 100 mock dai tokens to investor
    await underlyingToken.transfer(accounts[1], '100000000000000000000');

    // deploy cake stakin pool
    await deployer.deploy(CakeStakingPool, CAKE_MASTER_CHEF, governanceToken.address, accounts[0], PANCAKE_ROUTER, 10 )
    const cakeStakingPool = await CakeStakingPool.deployed()

    // transfer some cake tokens to cake staking pool
    await cakeToken.transfer(CakeStakingPool.address, "10000000000000000000000");

    // transfer 100 Mock cake tokens to investor
    await cakeToken.transfer(accounts[1], '100000000000000000000' );


};