// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import "./owner/Operator.sol";

contract VShare is ERC20Burnable, Operator {
  using SafeMath for uint256;

  uint256 public constant REWARD_POOL_ALLOCATION = 60000 ether;
  uint256 public constant DEV_FUND_POOL_ALLOCATION = 10000 ether;

  bool public rewardsDistributed = false;

  uint256 public constant VESTING_DURATION = 730 days;
  uint256 public startTime;
  uint256 public endTime;

  uint256 public devFundRewardRate;
  address public devFund;
  uint256 public devFundLastClaimed;

  constructor(uint256 _startTime, address _devFund) ERC20("VSHARE", "VSHARE") {
    _mint(msg.sender, 10 ether); // mint 10 VSHARE for initial pools deployment

    startTime = _startTime;
    endTime = startTime + VESTING_DURATION;

    devFundLastClaimed = startTime;
    devFundRewardRate = DEV_FUND_POOL_ALLOCATION.div(VESTING_DURATION);

    require(_devFund != address(0), "Address cannot be 0");
    devFund = _devFund;
  }

  function setDevFund(address _devFund) external {
    require(msg.sender == devFund, "!dev");
    require(_devFund != address(0), "zero");
    devFund = _devFund;
  }

  function unclaimedDevFund() public view returns (uint256 _pending) {
    uint256 _now = block.timestamp;
    if (_now > endTime) _now = endTime;
    if (devFundLastClaimed >= _now) return 0;
    _pending = _now.sub(devFundLastClaimed).mul(devFundRewardRate);
  }

  /**
   * @dev Claim pending rewards to community and dev fund
   */
  function claimRewards() external {
    uint256 _pending = unclaimedDevFund();
    if (_pending > 0 && devFund != address(0)) {
      _mint(devFund, _pending);
      devFundLastClaimed = block.timestamp;
    }
  }

  /**
   * @notice distribute to reward pool (only once)
   */
  function distributeReward(address _rewardPool) external onlyOperator {
    require(_rewardPool != address(0), "!_rewardPool");
    require(!rewardsDistributed, "only can distribute once");
    rewardsDistributed = true;
    _mint(_rewardPool, REWARD_POOL_ALLOCATION);
  }

  function burn(uint256 amount) public override {
    super.burn(amount);
  }

  function governanceRecoverUnsupported(
    IERC20 _token,
    uint256 _amount,
    address _to
  ) external onlyOperator {
    _token.transfer(_to, _amount);
  }
}
