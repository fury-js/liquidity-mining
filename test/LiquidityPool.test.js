const chai = require('chai')
chai.use(require('chai-as-promised'))

const expect = chai.expect


const LiqudityPool = artifacts.require('LiquidityPool')
const UnderlyingToken = artifacts.require('UnderlyingToken');
const GovernanceToken = artifacts.require('GovernanceToken');

function tokens(n) {
    return web3.utils.toWei(n, 'ether')
}




contract('LiquidityPool', ([owner, investor]) => {

	let liquidityPool

	beforeEach(async () => {
		underlyingToken = await UnderlyingToken.new()
		governanceToken = await GovernanceToken.new()
		liquidityPool = await LiqudityPool.new(underlyingToken.address, governanceToken.address)


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

    describe('farming tokens', () => {
        it('contract accepts deposit and withdrawal of mock dai Tokens', async () => {
            let result
            let investorDepositBlocknumber = 1;
            // let investorWithdrawBlocknumber = 10;


            // check investor balance before staking
            result = await underlyingToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('100', 'investor mock dai balance correct before staking '))

            // stake mock dai
            await underlyingToken.approve(liquidityPool.address, tokens('100'), { from: investor})
            await liquidityPool.deposit(tokens('100'), {from: investor})
            
            // check staking results
            result = await underlyingToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('0'), 'investor mock dai balance correct after staking' )

            result = await underlyingToken.balanceOf(liquidityPool.address)
            assert.equal(result.toString(), tokens('100'), 'tokenFarm mock dai balance correct after staking')

            result = await liquidityPool.stakingBalance(investor)
            assert.equal(result.toString(), tokens('100', 'investor staking balance correct after staking'))

            result = await liquidityPool.isStaking(investor)
            assert.equal(result.toString(), 'true', 'investor staking status correct after staking')

            // check that investor can withdraw mock dai tokens
            await liquidityPool.withdraw(tokens('100'), {from: investor})

            // check investor mock dai balance after unstaking
            result = await underlyingToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('100'), 'investor mock dai balance correct after unstaking')

            // check investor staking balance on tokenFarm after unstaking
            result = await liquidityPool.stakingBalance(investor)
            assert.equal(result.toString(), tokens('0'), 'investor staking balance correct after unstaking') 

            result = await liquidityPool.isStaking(investor)
            assert.equal(result.toString(), 'false', 'investor staking status correct after unstaking')

        })

        it('rewards investors with the Governance Token ', async () => {
        	// stake mock dai
            await underlyingToken.approve(liquidityPool.address, tokens('100'), { from: investor})
            await liquidityPool.deposit(tokens('100'), {from: investor})
            // withdraw mock dai
        	await liquidityPool.withdraw(tokens('100'), {from: investor})

        	// check Governance Token Balance of investor after withdrawal
            result = await governanceToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('10'), 'investor governance Token balance correct after issuance')
        })

        it('subtracts fee from withdrawal before timelock expires', async () => {
            // stake mock dai
            await underlyingToken.approve(liquidityPool.address, tokens('100'), {from: investor})
            await liquidityPool.lockedDeposit(tokens('100'), {from: investor})
            // withdraw mock dai
            await liquidityPool.lockedWithdraw(tokens('100'), {from: investor})
            result = await underlyingToken.balanceOf(investor)
            assert.equal(result.toString(), tokens('50'), 'fee substracted from investor  staked amount')
        })
    })

})