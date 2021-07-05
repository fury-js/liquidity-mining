const chai = require('chai')
chai.use(require('chai-as-promised'))

const expect = chai.expect

const CakeStakingPool = artifacts.require('CakeStakingPool');
const MockCakeToken = artifacts.require('MockCakeToken');
const GovernanceToken = artifacts.require('GovernanceToken');
const CAKE_MASTER_CHEF = '0x73feaa1eE314F8c655E354234017bE2193C9E24E';
const PANCAKE_ROUTER = '0x10ED43C718714eb63d5aA57B78B54704E256024E';



contract('CakeStakingPool', ([owner, investor]) => {

	let cakeStakingPool

	beforeEach(async () => {
		mockCakeToken = await MockCakeToken.new()
		governanceToken = await GovernanceToken.new()
		cakeStakingPool = await CakeStakingPool.new(CAKE_MASTER_CHEF, governanceToken.address, owner, PANCAKE_ROUTER, 10)


		// Transfer all nec tokens to farm
        await governanceToken.transfer(liquidityPool.address,tokens('1000000'))

        // transfer some underlying tokens to an investor
        await underlyingToken.transfer(investor, tokens('100'), {from: owner})
	})

	describe('Underlying Token deployement',  () => {
        it('has a name', async () => {
            const name =await underlyingToken.name()
            assert.equal(name, 'Mock Dai Token')
        })
    })

    describe('Governance Token deployement',  () => {
        it('has a name', async () => {
            const name =await governanceToken.name()
            assert.equal(name, 'Governance Token')
        })
    })

    describe(' LiquidityPool deployement',  () => {
        it('has a name', async () => {
            const name =await liquidityPool.name()
            assert.equal(name, 'Lp Token')
        })

        it('contract has all tokens', async () => {
            let balance = await governanceToken.balanceOf(liquidityPool.address)
            assert.equal(balance.toString(), tokens('1000000'))
        })
    })
})