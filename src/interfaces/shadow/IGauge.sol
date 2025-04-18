// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.26;
interface IGauge {
  error ZERO_AMOUNT();

  error CANT_NOTIFY_STAKE();

  error REWARD_TOO_HIGH();

  error NOT_GREATER_THAN_REMAINING(uint256 amount, uint256 remaining);

  error TOKEN_ERROR(address token);

  error NOT_WHITELISTED();

  error NOT_AUTHORIZED();

  event Deposit(address indexed from, uint256 amount);

  event Withdraw(address indexed from, uint256 amount);

  event NotifyReward(address indexed from, address indexed reward, uint256 amount);

  event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

  event RewardWhitelisted(address indexed reward, bool whitelisted);

  /// @notice Get the amount of stakingToken deposited by an account
  function balanceOf(address) external view returns (uint256);

  /// @notice returns an array with all the addresses of the rewards
  /// @return _rewards array of addresses for rewards
  function rewardsList() external view returns (address[] memory _rewards);

  /// @notice number of different rewards the gauge has facilitated that are 'active'
  /// @return _length the number of individual rewards
  function rewardsListLength() external view returns (uint256 _length);

  /// @notice returns the last time the reward was modified or periodFinish if the reward has ended
  /// @param token address of the token
  /// @return ltra last time reward applicable
  function lastTimeRewardApplicable(address token) external view returns (uint256 ltra);

  /// @notice displays the data struct of rewards for a token
  /// @param token the address of the token
  /// @return data rewards struct
  function rewardData(address token) external view returns (Reward memory data);

  /// @notice calculates the amount of tokens earned for an address
  /// @param token address of the token to check
  /// @param account address to check
  /// @return _reward amount of token claimable
  function earned(address token, address account) external view returns (uint256 _reward);
  /// @notice claims rewards (shadow + any external LP Incentives)
  /// @param account the address to claim for
  /// @param tokens an array of the tokens to claim
  function getReward(address account, address[] calldata tokens) external;

  /// @notice claims all rewards and instant exits xshadow into shadow
  function getRewardAndExit(address account, address[] calldata tokens) external;

  /// @notice calculates the token amounts earned per lp token
  /// @param token address of the token to check
  /// @return rpt reward per token
  function rewardPerToken(address token) external view returns (uint256 rpt);

  /// @notice deposit all LP tokens from msg.sender's wallet to the gauge
  function depositAll() external;
  /// @param recipient the address of who to deposit on behalf of
  /// @param amount the amount of LP tokens to withdraw
  function depositFor(address recipient, uint256 amount) external;

  /// @notice deposit LP tokens to the gauge
  /// @param amount the amount of LP tokens to withdraw
  function deposit(uint256 amount) external;

  /// @notice withdraws all fungible LP tokens from legacy gauges
  function withdrawAll() external;

  /// @notice withdraws fungible LP tokens from legacy gauges
  /// @param amount the amount of LP tokens to withdraw
  function withdraw(uint256 amount) external;

  /// @notice calculates how many tokens are left to be distributed
  /// @dev reduces per second
  /// @param token the address of the token
  function left(address token) external view returns (uint256);
  /// @notice add a reward to the whitelist
  /// @param _reward address of the reward
  function whitelistReward(address _reward) external;

  /// @notice remove rewards from the whitelist
  /// @param _reward address of the reward
  function removeRewardWhitelist(address _reward) external;

  /**
   * @notice amount must be greater than left() for the token, this is to prevent griefing attacks
   * @notice notifying rewards is completely permissionless
   * @notice if nobody registers for a newly added reward for the period it will remain in the contract indefinitely
   */
  function notifyRewardAmount(address token, uint256 amount) external;

  struct Reward {
    /// @dev tokens per second
    uint256 rewardRate;
    /// @dev 7 days after start
    uint256 periodFinish;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
  }

  /// @notice checks if a reward is whitelisted
  /// @param reward the address of the reward
  /// @return true if the reward is whitelisted, false otherwise
  function isWhitelisted(address reward) external view returns (bool);
}
