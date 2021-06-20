pragma solidity ^0.8.0;

import './UnderlyingToken.sol';
import './LpToken.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract LiquidityPool is LpToken {
	mapping(address => uint) public checkpoints;
	UnderlyingToken public underlyingToken;
	IERC20 public thothToken;
	uint constant public REWARD_PER_BLOCK = 1;


	address[] public stakers;
    mapping(address => uint) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;




	constructor(address _underlyingToken, address _governanceToken) {
		underlyingToken = UnderlyingToken(_underlyingToken);
		thothToken = IERC20(_governanceToken);
	}


	function deposit(uint amount) external {
		if(checkpoints[msg.sender] == 0) {
			checkpoints[msg.sender] = block.number;
		}

		_distributeRewards(msg.sender);
		underlyingToken.transferFrom(msg.sender, address(this), amount);

		// update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + amount;

		_mint(msg.sender, amount);

		// add user to stakers array only if they haven"t staked
        if(!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }

        // update staking staus
        hasStaked[msg.sender] = true;
        isStaking[msg.sender] = true;
	}

	function withdraw(uint amount) external {
		// fetch staking balance
        uint balance = stakingBalance[msg.sender];

        require( balance > 0, "insufficient balance");
		require(balanceOf(msg.sender) >= amount, 'not enough LP Tokens');

		// reset staking balance
        stakingBalance[msg.sender] = 0;

        // update staking status
        isStaking[msg.sender] = false;
        hasStaked[msg.sender] = false;
        
		_distributeRewards(msg.sender);
		underlyingToken.transfer(msg.sender, amount);
		_burn(msg.sender, amount);

	}


	function _distributeRewards(address beneficiary) internal {
		uint checkpoint = checkpoints[beneficiary];
		if(block.number - checkpoint > 0 ) {
			uint distributionAmount = balanceOf(beneficiary) * (block.number - checkpoint ) * REWARD_PER_BLOCK;

			thothToken.transfer(beneficiary, distributionAmount);
			checkpoints[beneficiary] = block.number;
		}
	}
}