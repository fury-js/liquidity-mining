pragma solidity ^0.8.0;

import './UnderlyingToken.sol';
import './LpToken.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/access/Ownable.sol';



contract LiquidityPool is LpToken, Ownable {
	using SafeMath for uint;

	UnderlyingToken public underlyingToken;
	IERC20 public thothToken;
	// uint constant public REWARD_PER_BLOCK = 1;
	uint private REWARD_PERCENTAGE = 10;
	uint private LOCKED_REWARD_PERCENTAGE = 20;
	address public feeAccount; // account for exchange fees
	uint256 public feePercent = 50; // percent for the exchange


	uint private constant duration = 2 days;
	uint public immutable end;


	address[] public stakers;
	mapping(address => uint) public checkpoints;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public lockedStakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => mapping(address => uint256)) public tokens;





	constructor(address _underlyingToken, address _governanceToken) {
		underlyingToken = UnderlyingToken(_underlyingToken);
		thothToken = IERC20(_governanceToken);
		end = block.timestamp.add(duration);
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

	function lockedDeposit(uint amount) external {
		if(checkpoints[msg.sender] == 0) {
			checkpoints[msg.sender] = block.number;
		}

		_distributeRewardsForlockedStaking(msg.sender);
		underlyingToken.transferFrom(msg.sender, address(this), amount);

		// update staking balance
        lockedStakingBalance[msg.sender] = lockedStakingBalance[msg.sender].add(amount);

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

	function _withdrawBeforeTimelockexpires(uint amount) internal {
		// fetch staking balance
        uint balance = lockedStakingBalance[msg.sender];
        uint256 _feeAmount = amount.mul(feePercent).div(100);

        

        require( balance > 0, "insufficient balance");
		require(balanceOf(msg.sender) >= amount, 'not enough LP Tokens');

		// reset staking balance
        lockedStakingBalance[msg.sender] = 0;

        // update staking status
        isStaking[msg.sender] = false;
        hasStaked[msg.sender] = false;
        
		_distributeRewardsForlockedStaking(msg.sender);
		underlyingToken.transfer(msg.sender, amount.sub(_feeAmount));
		underlyingToken.transfer(address(this), _feeAmount);
		_burn(msg.sender, amount);

	}

	function lockedWithdraw(uint amount) external {
		if(block.timestamp >= end) {
			// fetch staking balance
	        uint balance = lockedStakingBalance[msg.sender];
	        require( balance > 0, "insufficient balance");
			require(balanceOf(msg.sender) >= amount, 'not enough LP Tokens');

			// reset staking balance
	        lockedStakingBalance[msg.sender] = 0;

	        // update staking status
	        isStaking[msg.sender] = false;
	        hasStaked[msg.sender] = false;
	        
			_distributeRewardsForlockedStaking(msg.sender);
			underlyingToken.transfer(msg.sender, amount);
			_burn(msg.sender, amount);
		} 
		else {
			_withdrawBeforeTimelockexpires(amount);
		}
		
		

	}

	function _distributeRewardsForlockedStaking(address beneficiary) internal {
		uint checkpoint = checkpoints[beneficiary];
		if(block.number - checkpoint > 0 ) {
			uint distributionAmount = (balanceOf(beneficiary) / 100 * LOCKED_REWARD_PERCENTAGE ) + (block.number-checkpoint) ;

			thothToken.transfer(beneficiary, distributionAmount);
			checkpoints[beneficiary] = block.number;
		}
	}


	function _distributeRewards(address beneficiary) internal {
		uint checkpoint = checkpoints[beneficiary];
		if(block.number - checkpoint > 0 ) {
			uint distributionAmount = balanceOf(beneficiary) * (block.number - checkpoint ) / REWARD_PERCENTAGE;

			thothToken.transfer(beneficiary, distributionAmount);
			checkpoints[beneficiary] = block.number;
		}
	}
}