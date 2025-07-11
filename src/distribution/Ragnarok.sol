// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/IBasisAsset.sol";

import "../interfaces/shadow/IGauge.sol";
import "../interfaces/shadow/IVoter.sol";

contract Ragnarok is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // governance
  address public operator;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many LP tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }

  struct GaugeInfo {
    bool isGauge; // If this is a gauge
    IGauge gauge; // The gauge
    address[] rewardTokens; // tokens that are used in the gauge
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 token; // Address of LP token contract.
    uint256 depFee; // deposit fee that is applied to created pool.
    uint256 allocPoint; // How many allocation points assigned to this pool. VALs to distribute per block.
    uint256 lastRewardTime; // Last time that VALs distribution occurs.
    uint256 accValhallaPerShare; // Accumulated VALs per share, times 1e18. See below.
    bool isStarted; // if lastRewardTime has passed
    GaugeInfo gaugeInfo; // Gauge info (does this pool have a gauge and where is it)
    uint256 poolValhallaPerSec; // rewards per second for pool (acts as allocPoint)
  }

  IERC20 public valhalla;
  IVoter public voter;
  address public xSHADOW = 0x5050bc082FF4A74Fb6B0B04385dEfdDB114b2424;
  address public devFund;

  // Info of each pool.
  PoolInfo[] public poolInfo;

  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  // The time when VAL mining starts.
  uint256 public poolStartTime;

  // The time when VAL mining ends.
  uint256 public poolEndTime;
  uint256 public valhallaPerSecond = 0 ether;
  uint256 public runningTime = 7 days;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event RewardPaid(address indexed user, uint256 amount);

  constructor(address _valhalla, address _devFund, uint256 _poolStartTime, address _voter) {
    require(block.timestamp < _poolStartTime, "pool cant be started in the past");
    if (_valhalla != address(0)) valhalla = IERC20(_valhalla);
    if (_devFund != address(0)) devFund = _devFund;

    poolStartTime = _poolStartTime;
    poolEndTime = _poolStartTime + runningTime;
    operator = msg.sender;
    voter = IVoter(_voter);
    devFund = _devFund;

    // create all the pools (daily rewards divided by 86400 seconds)
    // add(0.237268519 ether, 0, IERC20(address(0)), false, 0); // VAL-OS LP 143.5k (20500/86400)
    add(0.115740741 ether, 150, IERC20(0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794), false, 0); // OS 70k (10000/86400)
    add(0.138888889 ether, 150, IERC20(0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE), false, 0); // SCUSD 84k (12000/86400)
    add(0.0891203704 ether, 150, IERC20(0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812), false, 0); // SCETH 53.9k (7700/86400)
    add(0.0891203704 ether, 150, IERC20(0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd), false, 0); // SCBTC 53.9k (7700/86400)
    add(0.0405092593 ether, 150, IERC20(0xE5DA20F15420aD15DE0fa650600aFc998bbE3955), false, 0); // STS 24.5k (3500/86400)
    add(0.0405092593 ether, 150, IERC20(0x3333b97138D4b086720b5aE8A7844b1345a33333), false, 0); // SHADOW 24.5k (3500/86400)
    add(0.0324074074 ether, 150, IERC20(0x3333111A391cC08fa51353E9195526A70b333333), false, 0); // X33 19.6k (2800/86400)
    add(0.0324074074 ether, 150, IERC20(0x7A0C53F7eb34C5BC8B01691723669adA9D6CB384), false, 0); // BOO 19.6k (2800/86400)
    add(0.0324074074 ether, 150, IERC20(0xddF26B42C1d903De8962d3F79a74a501420d5F19), false, 0); // EQUAL 19.6k (2800/86400)
    add(0.0289351852 ether, 150, IERC20(0xf26Ff70573ddc8a90Bd7865AF8d7d70B8Ff019bC), false, 0); // EGGS 17.5k (2500/86400)
    add(0.0173611111 ether, 150, IERC20(0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C), false, 0); // ANON 10.5k (1500/86400)
    add(0.0133101852 ether, 150, IERC20(0xe920d1DA9A4D59126dC35996Ea242d60EFca1304), false, 0); // DERP 8.05k (1150/86400)
    add(0.0115740741 ether, 150, IERC20(0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564), false, 0); // GOGLZ 7k (1000/86400)
    add(0.0115740741 ether, 150, IERC20(0x6fB9897896Fe5D05025Eb43306675727887D0B7c), false, 0); // HEDGY 7k (1000/86400)
    add(0.0150462963 ether, 150, IERC20(0x31E2eed04a62b232DA964A097D8C171584e3C3Bd), false, 0); // OIL 9.1k (1300/86400)
    add(0.0115740741 ether, 150, IERC20(0xf4F9C50455C698834Bb645089DbAa89093b93838), false, 0); // TOONA 7k (1000/86400)
    add(0.0115740741 ether, 150, IERC20(0xE51EE9868C1f0d6cd968A8B8C8376Dc2991BFE44), false, 0); // BRUSH 7k (1000/86400)
    add(0.00810185185 ether, 150, IERC20(0x7A08Bf5304094CA4C7b4132Ef62b5EDc4a3478B7), false, 0); // ECO 4.9k (700/86400)
  }

  modifier onlyOperator() {
    require(operator == msg.sender, "Ragnarok: caller is not the operator");
    _;
  }

  function poolLength() external view returns (uint256) {
    return poolInfo.length;
  }

  struct PoolData {
    uint256 pid;
    address token;
    uint256 poolBalance;
    uint256 stakeBalance;
    uint256 stakeEarnings;
  }

  function getPoolData(address userAddress) external view returns (PoolData[] memory) {
    // Create array of 19 PoolData that we will return
    PoolData[] memory poolDataArray = new PoolData[](19);

    for (uint256 pid = 0; pid < 19; pid++) {
      PoolInfo memory pool = poolInfo[pid];
      uint256 tokenBalance = pool.token.balanceOf(address(this));
      UserInfo memory user = userInfo[pid][userAddress];

      // Populate pool data
      poolDataArray[pid] = PoolData({
        pid: pid,
        token: address(pool.token),
        poolBalance: tokenBalance,
        stakeBalance: user.amount,
        stakeEarnings: user.rewardDebt
      });
    }

    return poolDataArray;
  }

  function checkPoolDuplicate(IERC20 _token) internal view {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      require(poolInfo[pid].token != _token, "Ragnarok: existing pool?");
    }
  }

  // bulk add pools
  function addBulk(
    uint256[] calldata _allocPoints,
    uint256[] calldata _depFees,
    IERC20[] calldata _tokens,
    bool _withUpdate,
    uint256 _lastRewardTime
  ) external onlyOperator {
    require(
      _allocPoints.length == _depFees.length && _allocPoints.length == _tokens.length,
      "Ragnarok: invalid length"
    );
    for (uint256 i = 0; i < _allocPoints.length; i++) {
      add(_allocPoints[i], _depFees[i], _tokens[i], _withUpdate, _lastRewardTime);
    }
  }

  // Add new lp to the pool. Can only be called by operator.
  function add(
    uint256 _allocPoint,
    uint256 _depFee,
    IERC20 _token,
    bool _withUpdate,
    uint256 _lastRewardTime
  ) public onlyOperator {
    checkPoolDuplicate(_token);
    if (_withUpdate) {
      massUpdatePools();
    }
    if (block.timestamp < poolStartTime) {
      // chef is sleeping
      if (_lastRewardTime == 0) {
        _lastRewardTime = poolStartTime;
      } else {
        if (_lastRewardTime < poolStartTime) {
          _lastRewardTime = poolStartTime;
        }
      }
    } else {
      // chef is cooking
      if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
        _lastRewardTime = block.timestamp;
      }
    }
    bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
    address[] memory rewardTokensGauge = new address[](1);
    rewardTokensGauge[0] = xSHADOW;
    poolInfo.push(
      PoolInfo({
        token: _token,
        depFee: _depFee,
        allocPoint: _allocPoint,
        poolValhallaPerSec: _allocPoint,
        lastRewardTime: _lastRewardTime,
        accValhallaPerShare: 0,
        isStarted: _isStarted,
        gaugeInfo: GaugeInfo(false, IGauge(address(0)), rewardTokensGauge)
      })
    );

    if (_isStarted) {
      totalAllocPoint = totalAllocPoint.add(_allocPoint);
      valhallaPerSecond = valhallaPerSecond.add(_allocPoint);
    }
  }

  // Update the given pool's VAL allocation point. Can only be called by the operator.
  function set(uint256 _pid, uint256 _allocPoint, uint256 _depFee) public onlyOperator {
    massUpdatePools();

    PoolInfo storage pool = poolInfo[_pid];
    require(_depFee < 200); // deposit fee cant be more than 2%;
    pool.depFee = _depFee;

    if (pool.isStarted) {
      totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
      valhallaPerSecond = valhallaPerSecond.sub(pool.poolValhallaPerSec).add(_allocPoint);
    }
    pool.allocPoint = _allocPoint;
    pool.poolValhallaPerSec = _allocPoint;
  }

  function bulkSet(
    uint256[] calldata _pids,
    uint256[] calldata _allocPoints,
    uint256[] calldata _depFees
  ) external onlyOperator {
    require(
      _pids.length == _allocPoints.length && _pids.length == _depFees.length,
      "Ragnarok: invalid length"
    );
    for (uint256 i = 0; i < _pids.length; i++) {
      set(_pids[i], _allocPoints[i], _depFees[i]);
    }
  }

  // Return accumulate rewards over the given _from to _to block.
  function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
    if (_fromTime >= _toTime) return 0;
    if (_toTime >= poolEndTime) {
      if (_fromTime >= poolEndTime) return 0;
      if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(valhallaPerSecond);
      return poolEndTime.sub(_fromTime).mul(valhallaPerSecond);
    } else {
      if (_toTime <= poolStartTime) return 0;
      if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(valhallaPerSecond);
      return _toTime.sub(_fromTime).mul(valhallaPerSecond);
    }
  }

  // View function to see pending VALs on frontend.
  function pendingVAL(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accValhallaPerShare = pool.accValhallaPerShare;
    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
      uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
      uint256 _valhallaReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
      accValhallaPerShare = accValhallaPerShare.add(_valhallaReward.mul(1e18).div(tokenSupply));
    }
    return user.amount.mul(accValhallaPerShare).div(1e18).sub(user.rewardDebt);
  }

  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
      updatePoolWithGaugeDeposit(pid);
    }
  }

  // massUpdatePoolsInRange
  function massUpdatePoolsInRange(uint256 _fromPid, uint256 _toPid) public {
    require(_fromPid <= _toPid, "Ragnarok: invalid range");
    for (uint256 pid = _fromPid; pid <= _toPid; ++pid) {
      updatePool(pid);
      updatePoolWithGaugeDeposit(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) private {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.timestamp <= pool.lastRewardTime) {
      return;
    }
    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (tokenSupply == 0) {
      pool.lastRewardTime = block.timestamp;
      return;
    }
    if (!pool.isStarted) {
      pool.isStarted = true;
      totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
      valhallaPerSecond = valhallaPerSecond.add(pool.poolValhallaPerSec);
    }
    if (totalAllocPoint > 0) {
      uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
      uint256 _valhallaReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
      pool.accValhallaPerShare = pool.accValhallaPerShare.add(
        _valhallaReward.mul(1e18).div(tokenSupply)
      );
    }
    pool.lastRewardTime = block.timestamp;
    claimLegacyRewards(_pid);
  }

  // Deposit LP tokens to earn rewards
  function updatePoolWithGaugeDeposit(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    address gauge = address(pool.gaugeInfo.gauge);
    uint256 balance = pool.token.balanceOf(address(this));
    // Do nothing if this pool doesn't have a gauge
    if (pool.gaugeInfo.isGauge) {
      // Do nothing if the LP token in the MC is empty
      if (balance > 0) {
        // Approve to the gauge
        if (pool.token.allowance(address(this), gauge) < balance) {
          pool.token.approve(gauge, type(uint256).max);
        }
        // Deposit the LP in the gauge
        pool.gaugeInfo.gauge.depositFor(address(this), balance);
      }
    }
  }

  // Claim rewards to treasury
  function claimLegacyRewards(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (pool.gaugeInfo.isGauge) {
      if (pool.gaugeInfo.rewardTokens.length > 0) {
        uint256[] memory beforeBalances = new uint256[](pool.gaugeInfo.rewardTokens.length);

        // Store balances before claim
        for (uint256 i = 0; i < pool.gaugeInfo.rewardTokens.length; i++) {
          beforeBalances[i] = IERC20(pool.gaugeInfo.rewardTokens[i]).balanceOf(address(this));
        }

        address[] memory gaugesToCheck = new address[](1);
        gaugesToCheck[0] = address(pool.gaugeInfo.gauge);

        address[][] memory gaugeRewardTokens = new address[][](1);
        gaugeRewardTokens[0] = pool.gaugeInfo.rewardTokens;

        voter.claimRewards(gaugesToCheck, gaugeRewardTokens);

        for (uint256 i = 0; i < pool.gaugeInfo.rewardTokens.length; i++) {
          IERC20 rewardToken = IERC20(pool.gaugeInfo.rewardTokens[i]);
          uint256 afterBalance = rewardToken.balanceOf(address(this));
          uint256 rewardAmount = afterBalance - beforeBalances[i];

          if (rewardAmount > 0) {
            rewardToken.safeTransfer(devFund, rewardAmount);
          }
        }
      }
    }
  }

  // Add a gauge to a pool
  function enableGauge(uint256 _pid) public onlyOperator {
    address gauge = voter.gaugeForPool(address(poolInfo[_pid].token));
    if (gauge != address(0)) {
      address[] memory rewardTokensGauge = new address[](1);
      rewardTokensGauge[0] = xSHADOW;
      poolInfo[_pid].gaugeInfo = GaugeInfo(true, IGauge(gauge), rewardTokensGauge);
    }
  }

  function setGaugeRewardTokens(
    uint256 _pid,
    address[] calldata _rewardTokens
  ) public onlyOperator {
    PoolInfo storage pool = poolInfo[_pid];
    require(pool.gaugeInfo.isGauge, "Ragnarok: not a gauge pool");
    pool.gaugeInfo.rewardTokens = _rewardTokens;
  }

  function setDevFund(address _devFund) public onlyOperator {
    devFund = _devFund;
  }

  // Withdraw LP from the gauge
  function withdrawFromGauge(uint256 _pid, uint256 _amount) internal {
    PoolInfo storage pool = poolInfo[_pid];
    // Do nothing if this pool doesn't have a gauge
    if (pool.gaugeInfo.isGauge) {
      // Withdraw from the gauge
      pool.gaugeInfo.gauge.withdraw(_amount);
    }
  }

  // Deposit LP tokens.
  function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
    address _sender = msg.sender;
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 _pending = user.amount.mul(pool.accValhallaPerShare).div(1e18).sub(user.rewardDebt);
      if (_pending > 0) {
        safeValhallaTransfer(_sender, _pending);
        emit RewardPaid(_sender, _pending);
      }
    }
    if (_amount > 0) {
      pool.token.safeTransferFrom(_sender, address(this), _amount);
      uint256 depositDebt = _amount.mul(pool.depFee).div(10000);
      user.amount = user.amount.add(_amount.sub(depositDebt));
      pool.token.safeTransfer(devFund, depositDebt);
    }
    updatePoolWithGaugeDeposit(_pid);
    user.rewardDebt = user.amount.mul(pool.accValhallaPerShare).div(1e18);
    emit Deposit(_sender, _pid, _amount);
  }

  // Withdraw LP tokens.
  function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
    address _sender = msg.sender;
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_sender];
    require(user.amount >= _amount, "withdraw: not good");
    updatePool(_pid);
    updatePoolWithGaugeDeposit(_pid);
    uint256 _pending = user.amount.mul(pool.accValhallaPerShare).div(1e18).sub(user.rewardDebt);
    if (_pending > 0) {
      safeValhallaTransfer(_sender, _pending);
      emit RewardPaid(_sender, _pending);
    }
    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      withdrawFromGauge(_pid, _amount);
      pool.token.safeTransfer(_sender, _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accValhallaPerShare).div(1e18);
    emit Withdraw(_sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) public nonReentrant {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 _amount = user.amount;
    withdrawFromGauge(_pid, _amount);
    user.amount = 0;
    user.rewardDebt = 0;
    pool.token.safeTransfer(msg.sender, _amount);
    emit EmergencyWithdraw(msg.sender, _pid, _amount);
  }

  // Safe valhalla transfer function, just in case if rounding error causes pool to not have enough VALs.
  function safeValhallaTransfer(address _to, uint256 _amount) internal {
    uint256 _valhallaBal = valhalla.balanceOf(address(this));
    if (_valhallaBal > 0) {
      if (_amount > _valhallaBal) {
        valhalla.safeTransfer(_to, _valhallaBal);
      } else {
        valhalla.safeTransfer(_to, _amount);
      }
    }
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

}
