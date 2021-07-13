pragma solidity ^0.8.0;


import './IPancake.sol';
import './IMasterChef.sol';
import './UnderlyingToken.sol';
import './LpToken.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "openzeppelin-solidity/contracts/math/SafeMath.sol";



contract CakeStakingPool is LpToken, Ownable {
	using SafeMath for uint;

	IERC20 public  thothToken;
	IPancake public pancake;
	IMasterChef public CAKE_MASTER_CHEF;
	IERC20 public  CAKE = IERC20(0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82);
	address public adminAddress;
	uint public APY;

	address[] public stakers;
	mapping(address => uint) public checkpoints;
    mapping(address => uint) public stakingBalance;
    mapping(address => uint) public lockedStakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

	constructor(address _cakeMasterChef, address _thothToken, address _adminAddress, address _pancake, uint _apy) {
		CAKE_MASTER_CHEF = IMasterChef(_cakeMasterChef);
		thothToken = IERC20(_thothToken);
		adminAddress = _adminAddress;
		pancake = IPancake(_pancake);
		APY = _apy;
	}

	modifier onlyAdmin() {
		require(msg.sender == adminAddress, 'only admin');
		_;
	}

	// Update admin
	function setAdmin(address _adminAddress) public onlyOwner {
		adminAddress = _adminAddress;
	}


	function deposit(uint amount) external {
		require(amount > 0, 'amount cannot be 0');
		if(checkpoints[msg.sender] == 0) {
			checkpoints[msg.sender] = block.timestamp;
		}
		// CAKE.transferFrom(msg.sender, address(this), amount);
		CAKE.approve(address(this), amount);
		CAKE_MASTER_CHEF.enterStaking(amount);
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
		require(amount > 0, 'amount cannot be 0');
		// fectch staking balance
		uint balance = stakingBalance[msg.sender];

		require(balance > 0, 'insufficient funds');
		require(balanceOf(msg.sender) >= amount, 'not enough LP tokens');

		// withdraw tokens from cake masterchef
		CAKE_MASTER_CHEF.leaveStaking(amount);
		uint cakeBalance = CAKE.balanceOf(address(this));
		require(cakeBalance >= amount, 'withdrawal from cake masterchef has failed');
		_distributeRewards(msg.sender);
		_burn(msg.sender, amount); 
	}

	// function swap(address _cake, address _thothToken, uint amountOut, uint amountInMax, uint deadline) public onlyAdmin {
	// 	address[] memory path = new address[](2);
	// 	path[0] = _cake;
	// 	path[1] = _thothToken;
	// 	CAKE.approve(pancake, amountOut);
	// 	pancake.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);
	// }

	function _distributeRewards(address beneficiary) internal {
		uint userTimeofDeposit = checkpoints[beneficiary];
		uint amount = balanceOf(beneficiary);
		uint distributionAmount = _calculateDistributionAmount(userTimeofDeposit, amount);
		CAKE.transfer(beneficiary, distributionAmount); 
		thothToken.transfer(beneficiary, amount);
	}




	function _calculateDistributionAmount(uint time, uint amount) internal view returns(uint) {
		// calculate cake rewards using timestamp
		uint distribution = time.add(block.timestamp).mul(APY);
		uint distributionAmount = amount.add(distribution);
		return distributionAmount;
	}
}