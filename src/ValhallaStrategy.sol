// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { IERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/Math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { IOracle } from "./interfaces/IOracle.sol";
import { IRouter } from "./interfaces/IRouter.sol";

// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)
/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
  /**
   * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
   * given ``owner``'s signed approval.
   *
   * IMPORTANT: The same issues {IERC20-approve} has related to transaction
   * ordering also apply here.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `deadline` must be a timestamp in the future.
   * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
   * over the EIP712-formatted function arguments.
   * - the signature must use ``owner``'s current nonce (see {nonces}).
   *
   * For more information on the signature format, see the
   * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
   * section].
   *
   * CAUTION: See Security Considerations above.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Returns the current nonce for `owner`. This value must be
   * included whenever a signature is generated for {permit}.
   *
   * Every successful call to {permit} increases ``owner``'s nonce by one. This
   * prevents a signature from being used multiple times.
   */
  function nonces(address owner) external view returns (uint256);

  /**
   * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
   */
  // solhint-disable-next-line func-name-mixedcase
  function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IStrategy {
  // Total want tokens managed by strategy
  function wantLockedTotal() external view returns (uint256);

  // Sum of all shares of users to wantLockedTotal
  function sharesTotal() external view returns (uint256);

  function wantAddress() external view returns (address);

  function token0Address() external view returns (address);

  function token1Address() external view returns (address);

  function earnedAddress() external view returns (address);

  function getPricePerFullShare() external view returns (uint256);

  // Main want token compounding function
  function earn() external;

  // Transfer want tokens autoFarm -> strategy
  function deposit(address _userAddress, uint256 _wantAmt) external returns (uint256);

  // Transfer want tokens strategy -> autoFarm
  function withdraw(address _userAddress, uint256 _wantAmt) external returns (uint256);

  function migrateFrom(
    address _oldStrategy,
    uint256 _oldWantLockedTotal,
    uint256 _oldSharesTotal
  ) external;

  function inCaseTokensGetStuck(address _token, uint256 _amount) external;

  function inFarmBalance() external view returns (uint256);

  function totalBalance() external view returns (uint256);
}

interface IFarmChef {
  function deposit(uint256 _pid, uint256 _amount) external;

  function withdraw(uint256 _pid, uint256 _amount) external;

  function pendingShare(uint256 _pid, address _user) external view returns (uint256);

  function pendingShareAndPendingRewards(
    uint256 _pid,
    address _user
  ) external view returns (uint256);

  function userInfo(
    uint256 _pid,
    address _user
  ) external view returns (uint256 amount, uint256 rewardDebt);

  function harvest(uint256 _pid) external payable;

  function gsnakeOracle() external view returns (address);

  function pegStabilityModuleFeeEnabled() external view returns (bool);

  function pegStabilityModuleFee() external view returns (uint256);
}

contract StrategySnake is IStrategy, Ownable, ReentrancyGuard, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public farmContractAddress = address(0xe6E0A10eb298F0aC4170f2502cF7b201375BBc85);
  address public dexRouterAddress = address(0x1D368773735ee1E678950B7A97bcA2CafB330CDc); //Shadow
  uint256 public pid;
  address public override wantAddress;
  address public override token0Address;
  address public override token1Address;
  address public override earnedAddress;
  bool public stable;
  mapping(address => mapping(address => IRouter.route[])) public tokenRoutes;

  address public constant WS = address(0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38);

  address public controller;
  address public strategist;
  address public timelock;

  uint256 public lastFeePaid = 0;
  uint256 public lastEarnTime = 0;
  uint256 public autoEarnLimit = 10 * 1e18; // 10 S

  uint256 public override wantLockedTotal = 0;
  uint256 public override sharesTotal = 0;
  uint256 public totalEarned = 0;

  uint256 public minSReserved = 100 * 1e18; //100 S reserved
  uint256 public adjustSlippageFee = 10; //1%
  uint256 public adjustSlippageFeeMax = 100; //10%
  uint256 public controllerFee = 50; //5%
  uint256 public constant controllerFeeMax = 100; // 10 = 1%
  uint256 public constant domination = 1000;

  address public treasuryAddress;

  event Deposit(uint256 amount);
  event Withdraw(uint256 amount);
  event Farm(uint256 amount);
  event Compound(
    address token0Address,
    uint256 token0Amt,
    address token1Address,
    uint256 token1Amt
  );
  event Earned(address earnedAddress, uint256 earnedAmt);
  event InCaseTokensGetStuck(address tokenAddress, uint256 tokenAmt, address receiver);
  event ExecuteTransaction(address indexed target, uint256 value, string signature, bytes data);
  event WithdrawS(address indexed user, uint256 amount);
  event Fees(uint256 collateralFee, uint256 collectedFee);

  constructor(
    address _controller,
    address _timelock,
    address _treasuryAddress,
    uint256 _pid,
    address _wantAddress,
    address _earnedAddress,
    address _token0,
    address _token1,
    bool _stable
  ) {
    controller = _controller;
    strategist = msg.sender;
    timelock = _timelock;
    treasuryAddress = _treasuryAddress;
    // to call earn if public not allowed
    wantAddress = _wantAddress;

    token0Address = _token0;
    token1Address = _token1;

    pid = _pid;
    earnedAddress = _earnedAddress;
    stable = _stable;
  }

  modifier onlyController() {
    require(controller == msg.sender, "caller is not the controller");
    _;
  }

  modifier onlyStrategist() {
    require(
      strategist == msg.sender || owner() == msg.sender,
      "Strategy: caller is not the strategist"
    );
    _;
  }

  modifier onlyTimelock() {
    require(timelock == msg.sender, "Strategy: caller is not timelock");
    _;
  }

  function isAuthorised(address _account) public view returns (bool) {
    return (_account == owner()) || (_account == strategist) || (_account == timelock);
  }

  function requiredSToHarvest() public view returns (uint256) {
    uint256 _pending = pendingHarvest();
    bool pegStabilityModuleFeeEnabled = IFarmChef(farmContractAddress)
      .pegStabilityModuleFeeEnabled();
    if (pegStabilityModuleFeeEnabled) {
      IOracle oracle = IOracle(IFarmChef(farmContractAddress).gsnakeOracle());
      // Calculate the required Sonic (S) amount to cover PSM fee (15% of pending reward value)
      uint256 currentGSNAKEPriceInSonic = oracle.twap(earnedAddress, 1e18);
      uint256 _pendingHarvestSValue = _pending.mul(currentGSNAKEPriceInSonic).div(1e18);
      uint256 pegStabilityModuleFee = IFarmChef(farmContractAddress).pegStabilityModuleFee();
      return _pendingHarvestSValue.mul(pegStabilityModuleFee + adjustSlippageFee).div(domination);
    }
    return 0;
  }

  function autoEarn() public onlyStrategist {
    uint256 _pendingHarvestSValue = pendingHarvestSValue();
    require(_pendingHarvestSValue >= autoEarnLimit, "too small");
    uint256 requiredS = requiredSToHarvest();

    require(address(this).balance >= requiredS, "not enough S collateral");
    earn();
  }

  function inFarmBalance() public view override returns (uint256) {
    (uint256 amount, ) = IFarmChef(farmContractAddress).userInfo(pid, address(this));
    return amount;
  }

  function totalBalance() external view override returns (uint256) {
    return IERC20(wantAddress).balanceOf(address(this)) + inFarmBalance();
  }

  function getPricePerFullShare() external view override returns (uint256) {
    return (sharesTotal == 0) ? 1e18 : wantLockedTotal.mul(1e18).div(sharesTotal);
  }

  function increaseAllowance(address token, address spender, uint256 addedValue) internal {
    // increase allowance
    IERC20(token).safeIncreaseAllowance(spender, addedValue);
  }

  // Receives new deposits from user
  function deposit(
    address,
    uint256 _wantAmt
  ) external override onlyController nonReentrant whenNotPaused returns (uint256) {
    IERC20(wantAddress).safeTransferFrom(address(msg.sender), address(this), _wantAmt);

    uint256 sharesAdded = _wantAmt;
    if (wantLockedTotal > 0 && sharesTotal > 0) {
      sharesAdded = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
    }
    sharesTotal = sharesTotal.add(sharesAdded);

    _farm();

    emit Deposit(_wantAmt);

    return sharesAdded;
  }

  function farm() public onlyOwner {
    _farm();
  }

  function harvestReward() public onlyOwner {
    _harvest();
  }

  function compound() public onlyOwner {
    _compound();
  }

  function payFees() public onlyOwner {
    _payFees();
  }

  function _farm() internal {
    IERC20 _want = IERC20(wantAddress);
    uint256 wantAmt = _want.balanceOf(address(this));
    wantLockedTotal = wantLockedTotal.add(wantAmt);
    if (wantAmt > 0) {
      increaseAllowance(wantAddress, farmContractAddress, wantAmt);
      IFarmChef(farmContractAddress).deposit(pid, wantAmt);
      emit Farm(wantAmt);
    }
  }

  function withdraw(
    address,
    uint256 _wantAmt
  ) external override onlyController nonReentrant returns (uint256) {
    require(_wantAmt > 0, "Strategy: !_wantAmt");

    IFarmChef(farmContractAddress).withdraw(pid, _wantAmt);

    uint256 wantAmt = IERC20(wantAddress).balanceOf(address(this));
    if (_wantAmt > wantAmt) {
      _wantAmt = wantAmt;
    }

    if (wantLockedTotal < _wantAmt) {
      _wantAmt = wantLockedTotal;
    }

    uint256 sharesRemoved = _wantAmt.mul(sharesTotal).div(wantLockedTotal);
    if (sharesRemoved > sharesTotal) {
      sharesRemoved = sharesTotal;
    }
    sharesTotal = sharesTotal.sub(sharesRemoved);
    wantLockedTotal = wantLockedTotal.sub(_wantAmt);

    IERC20(wantAddress).safeTransfer(address(msg.sender), _wantAmt);

    emit Withdraw(_wantAmt);

    return sharesRemoved;
  }
  function _harvest() internal {
    uint256 sBalanceBefore = address(this).balance;
    // Harvest farm tokens
    // Get pending rewards from farm contract
    uint256 pendingReward = IFarmChef(farmContractAddress).pendingShareAndPendingRewards(
      pid,
      address(this)
    );
    bool pegStabilityModuleFeeEnabled = IFarmChef(farmContractAddress)
      .pegStabilityModuleFeeEnabled();
    uint256 amountSonicToPay = 0;
    if (pegStabilityModuleFeeEnabled) {
      uint256 pegStabilityModuleFee = IFarmChef(farmContractAddress).pegStabilityModuleFee();
      IOracle oracle = IOracle(IFarmChef(farmContractAddress).gsnakeOracle());
      // Calculate the required Sonic (S) amount to cover PSM fee (15% of pending reward value)
      uint256 currentGSNAKEPriceInSonic = oracle.twap(earnedAddress, 1e18);
      require(currentGSNAKEPriceInSonic > 0, "Oracle price error");
      //add 1% to make sure enough Sonic to cover fee
      amountSonicToPay = (currentGSNAKEPriceInSonic.mul(pendingReward).div(1e18))
        .mul(pegStabilityModuleFee + adjustSlippageFee)
        .div(domination);
    }
    require(sBalanceBefore >= amountSonicToPay, "Not enough sonic collateral");
    // Harvest farm rewards before compounding, sending required Sonic (S)
    IFarmChef(farmContractAddress).harvest{ value: amountSonicToPay }(pid);
    lastFeePaid = sBalanceBefore - address(this).balance;
  }

  function _payFees() internal {
    uint256 earnedAmount = IERC20(earnedAddress).balanceOf(address(this));
    if (earnedAmount <= 0) {
      return;
    }
    emit Earned(earnedAddress, earnedAmount);

    uint256 estimateEarnedInS = exchangeRate(earnedAddress, WS, earnedAmount);
    if (estimateEarnedInS <= 0) {
      return;
    }
    uint256 percentEarnedNeedToSwapForFees = controllerFee;
    if (lastFeePaid > 0) {
      percentEarnedNeedToSwapForFees +=
        (lastFeePaid.mul(domination).div(estimateEarnedInS)) +
        adjustSlippageFee;
    }

    _swapTokenToS(
      earnedAddress,
      earnedAmount.mul(percentEarnedNeedToSwapForFees).div(domination),
      address(this)
    );
    uint256 sBalance = address(this).balance;
    uint256 collectedFee = 0;
    if (sBalance > minSReserved) {
      collectedFee = sBalance - minSReserved;
      (bool success, ) = payable(treasuryAddress).call{ value: collectedFee }("");
      require(success, "transfer fee failed!");
    }
    emit Fees(lastFeePaid, collectedFee);
  }

  function _compound() internal {
    //1. Convert earned token into want token
    uint256 earnedAmount = IERC20(earnedAddress).balanceOf(address(this));

    // track totalEarned in S
    totalEarned = totalEarned.add(exchangeRate(earnedAddress, WS, earnedAmount));

    // track quote liquidity of pair
    (uint256 amountA, uint256 amountB, ) = IRouter(dexRouterAddress).quoteAddLiquidity(
      token0Address,
      token1Address,
      stable,
      1e18,
      1e18
    );
    if (earnedAddress != token0Address) {
      uint256 token0Price = exchangeRate(token0Address, token1Address, 1e18);
      uint256 token0Value = amountA.mul(token0Price).div(1e18);
      uint256 totalValue = token0Value + amountB;
      _swapTokenToToken(
        earnedAddress,
        token0Address,
        earnedAmount.mul(token0Value).div(totalValue),
        address(this)
      );
    }

    // swap the rest earn amount to token 0
    earnedAmount = IERC20(earnedAddress).balanceOf(address(this));
    if (earnedAddress != token1Address) {
      _swapTokenToToken(earnedAddress, token1Address, earnedAmount, address(this));
    }

    // Get want tokens, ie. add liquidity
    uint256 token0Amt = IERC20(token0Address).balanceOf(address(this));
    uint256 token1Amt = IERC20(token1Address).balanceOf(address(this));
    if (token0Amt > 0 && token1Amt > 0) {
      _addLiquidity(token0Address, token1Address, stable, token0Amt, token1Amt);
      emit Compound(token0Address, token0Amt, token1Address, token1Amt);
    }
  }
  // 1. Harvest farm tokens
  // 2. Converts farm tokens into want tokens
  // 3. Deposits want tokens
  function earn() public override whenNotPaused onlyStrategist {
    _harvest();

    _payFees();

    _compound();

    _farm();

    lastEarnTime = block.timestamp;
  }

  function exchangeRate(
    address _inputToken,
    address _outputToken,
    uint256 _tokenAmount
  ) public view returns (uint256) {
    uint256[] memory amounts = IRouter(dexRouterAddress).getAmountsOut(
      _tokenAmount,
      tokenRoutes[_inputToken][_outputToken]
    );
    return amounts[amounts.length - 1];
  }

  function pendingHarvest() public view returns (uint256) {
    uint256 _earnedBal = IERC20(earnedAddress).balanceOf(address(this));
    return
      IFarmChef(farmContractAddress).pendingShareAndPendingRewards(pid, address(this)).add(
        _earnedBal
      );
  }

  function pendingHarvestSValue() public view returns (uint256) {
    uint256 _pending = pendingHarvest();
    return (_pending == 0) ? 0 : exchangeRate(earnedAddress, WS, _pending);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setStrategist(address _strategist) external onlyOwner {
    strategist = _strategist;
  }

  function setMinSReserved(uint256 _minSReserved) external onlyOwner {
    minSReserved = _minSReserved;
  }

  function setFees(uint256 _controllerFee, uint256 _adjustSlippageFee) external onlyOwner {
    require(_controllerFee <= controllerFeeMax, "Strategy: value too high");
    controllerFee = _controllerFee;
    require(adjustSlippageFee <= adjustSlippageFeeMax, "Strategy: value too high");
    adjustSlippageFee = _adjustSlippageFee;
  }

  function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
    require(_treasuryAddress != address(0), "zero");
    treasuryAddress = _treasuryAddress;
  }

  function setDexRouterAddress(address _routerAddress) external onlyOwner {
    require(_routerAddress != address(0), "zero");
    dexRouterAddress = _routerAddress;
  }

  function setAutoEarnLimit(uint256 _autoEarnLimit) external onlyOwner {
    autoEarnLimit = _autoEarnLimit;
  }

  function setMainPaths(
    IRouter.Route[] memory _earnedToToken0Path,
    IRouter.Route[] memory _earnedToToken1Path,
    IRouter.Route[] memory _earnedToWSPath,
    IRouter.Route[] memory _token0ToToken1Path
  ) external onlyOwner {
    setTokenRoute(earnedAddress, token0Address, _earnedToToken0Path);
    setTokenRoute(earnedAddress, token1Address, _earnedToToken1Path);
    setTokenRoute(earnedAddress, WS, _earnedToWSPath);
    setTokenRoute(token0Address, token1Address, _token0ToToken1Path);
  }

  function setTokenRoute(address from, address to, IRouter.Route[] memory routes) public onlyOwner {
    delete tokenRoutes[from][to];
    for (uint256 i = 0; i < routes.length; i++) {
      tokenRoutes[from][to].push(routes[i]);
    }
  }

  function _swapTokenToS(address _inputToken, uint256 _amount, address to) internal {
    increaseAllowance(_inputToken, dexRouterAddress, _amount);
    if (_inputToken != WS) {
      IRouter(dexRouterAddress).swapExactTokensForETH(
        _amount,
        0,
        tokenRoutes[_inputToken][WS],
        to,
        block.timestamp.add(1800)
      );
    }
  }

  function _swapTokenToToken(
    address _inputToken,
    address _outputToken,
    uint256 _amount,
    address to
  ) internal {
    increaseAllowance(_inputToken, dexRouterAddress, _amount);
    if (_inputToken != _outputToken) {
      IRouter(dexRouterAddress).swapExactTokensForTokens(
        _amount,
        0,
        tokenRoutes[_inputToken][_outputToken],
        to,
        block.timestamp.add(1800)
      );
    }
  }

  function _addLiquidity(
    address _tokenA,
    address _tokenB,
    bool _stable,
    uint256 _amountADesired,
    uint256 _amountBDesired
  ) internal {
    increaseAllowance(_tokenA, dexRouterAddress, _amountADesired);
    increaseAllowance(_tokenB, dexRouterAddress, _amountBDesired);
    IRouter(dexRouterAddress).addLiquidity(
      _tokenA,
      _tokenB,
      _stable,
      _amountADesired,
      _amountBDesired,
      0,
      0,
      address(this),
      block.timestamp.add(1800)
    );
  }

  receive() external payable {}

  fallback() external payable {}

  function withdrawS(uint256 amount) external onlyOwner {
    require(amount > 0, "Amount must be greater than zero");
    require(address(this).balance >= amount, "Insufficient S balance in contract");

    (bool success, ) = payable(treasuryAddress).call{ value: amount }("");
    require(success, "Withdraw failed");
    emit WithdrawS(msg.sender, amount);
  }

  function inCaseTokensGetStuck(address _token, uint256 _amount) external override onlyOwner {
    require(_token != earnedAddress, "!safe");
    require(_token != wantAddress, "!safe");
    address _controller = controller;
    IERC20(_token).safeTransfer(_controller, _amount);
    emit InCaseTokensGetStuck(_token, _amount, _controller);
  }

  function togglePause() external onlyOwner {
    if (paused()) _unpause();
    else _pause();
  }

  function migrateFrom(address, uint256, uint256) external override onlyController {}

  /* ========== EMERGENCY ========== */

  function setController(address _controller) external {
    require(_controller != address(0), "invalidAddress");
    require(
      controller == msg.sender || timelock == msg.sender,
      "caller is not the controller nor timelock"
    );
    controller = _controller;
  }

  function setTimelock(address _timelock) external {
    require(
      timelock == msg.sender || (timelock == address(0) && owner() == msg.sender),
      "!timelock"
    );
    timelock = _timelock;
  }

  /**
   * @dev This is from Timelock contract.
   */
  function executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data
  ) external onlyTimelock returns (bytes memory) {
    bytes memory callData;

    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    // solium-disable-next-line security/no-call-value
    (bool success, bytes memory returnData) = target.call{ value: value }(callData);
    require(success, "Strategy::executeTransaction: Transaction execution reverted.");

    emit ExecuteTransaction(target, value, signature, data);

    return returnData;
  }
}
