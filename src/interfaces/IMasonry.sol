// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasonry {
  function balanceOf(address _andras) external view returns (uint256);

  function earned(address _andras) external view returns (uint256);

  function canWithdraw(address _andras) external view returns (bool);

  function canClaimReward(address _andras) external view returns (bool);

  function epoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function getTombPrice() external view returns (uint256);

  function setOperator(address _operator) external;

  function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

  function stake(uint256 _amount) external;

  function withdraw(uint256 _amount) external;

  function exit() external;

  function claimReward() external;

  function allocateSeigniorage(uint256 _amount) external;

  function governanceRecoverUnsupported(address _token, uint256 _amount, address _to) external;
}
