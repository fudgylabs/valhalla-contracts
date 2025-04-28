// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
pragma abicoder v2;

import { Script, console } from "forge-std/Script.sol";
import { IERC20 } from "@/UniswapV3FlashSwap.sol"; // Or use OpenZeppelin
import { IWETH } from "@/UniswapV3FlashSwap.sol";
import { ISwapRouter } from "@/interfaces/ISwapRouter.sol";

interface IUniswapV3Pool {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(
    address recipient,
    bool zeroForOne,
    int256 amountSpecified,
    uint160 sqrtPriceLimitX96,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);
}

interface IUniswapV3SwapCallback {
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
address constant ANON = 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C;
address constant SWAP_ROUTER_02 = 0x9282a6C62932431B127753C1CD2ac4F6cC4CFD49;
address constant ANON_WETH_POOL_3000 = 0x297000941c155962B04760EcAeAA422757F20bc1;
address constant ANON_WETH_POOL_1000 = 0x267FB0fC7694AF30fFBCD3c27Ce7497A7Db73616;
uint24 constant FEE_0 = 3000;
uint24 constant FEE_1 = 10000;
uint160 constant MIN_SQRT_RATIO = 4295128739;
uint160 constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

contract ArbitrageContract is IUniswapV3SwapCallback {
  IERC20 private constant anon = IERC20(ANON);
  IWETH private constant weth = IWETH(WS);
  IUniswapV3Pool private constant pool0 = IUniswapV3Pool(ANON_WETH_POOL_3000);
  IUniswapV3Pool private constant pool1 = IUniswapV3Pool(ANON_WETH_POOL_1000);

  uint256 private constant WS_AMOUNT_IN = 10 * 1e18;

  struct SwapCallbackData {
    address tokenIn;
    address tokenOut;
    address poolAddress;
  }

  function executeArbitrage() external payable returns (uint256) {
    uint256 wsBalanceBefore = weth.balanceOf(address(this));
    console.log("wsBalanceBefore: ", wsBalanceBefore);
    uint256 anonBalanceBefore = anon.balanceOf(address(this));

    weth.deposit{ value: 10 ether }();

    address token0Pool0 = pool0.token0();
    bool zeroForOnePool0 = WS == token0Pool0;

    pool0.swap(
      address(this),
      zeroForOnePool0,
      int256(WS_AMOUNT_IN),
      zeroForOnePool0 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(SwapCallbackData(WS, ANON, address(pool0)))
    );

    uint256 anonReceived = anon.balanceOf(address(this)) - anonBalanceBefore;
    console.log("ANON received from first swap:", anonReceived);

    address token0Pool1 = pool1.token0();
    bool zeroForOnePool1 = ANON == token0Pool1;

    pool1.swap(
      address(this),
      zeroForOnePool1,
      int256(anonReceived),
      zeroForOnePool1 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(SwapCallbackData(ANON, WS, address(pool1)))
    );

    uint256 wsBalanceAfter = weth.balanceOf(address(this));
    uint256 wsReceived = wsBalanceAfter - wsBalanceBefore;
    console.log("WS received from second swap:", wsReceived);
    console.log("wsBalanceBefore: ", wsBalanceBefore);

    return wsReceived;
  }

  function executeArbitrage2() external payable returns (int256) {
    weth.deposit{ value: 10 ether }();

    uint256 wsBalanceBefore = weth.balanceOf(address(this));
    console.log("Initial WS balance:", wsBalanceBefore);

    uint256 anonBalanceBefore = anon.balanceOf(address(this));

    address token0Pool1 = pool1.token0();
    bool zeroForOnePool1 = WS == token0Pool1;

    // First swap: WS → ANON via pool1
    pool1.swap(
      address(this),
      zeroForOnePool1,
      int256(WS_AMOUNT_IN),
      zeroForOnePool1 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(SwapCallbackData(WS, ANON, address(pool1)))
    );

    uint256 anonReceived = anon.balanceOf(address(this)) - anonBalanceBefore;
    console.log("ANON received from first swap (via pool1):", anonReceived);

    address token0Pool0 = pool0.token0();
    bool zeroForOnePool0 = ANON == token0Pool0;

    // Second swap: ANON → WS via pool0
    pool0.swap(
      address(this),
      zeroForOnePool0,
      int256(anonReceived),
      zeroForOnePool0 ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
      abi.encode(SwapCallbackData(ANON, WS, address(pool0)))
    );

    uint256 wsBalanceAfter = weth.balanceOf(address(this));
    int256 wsProfit = int256(wsBalanceAfter) - int256(wsBalanceBefore);

    console.log("Final WS balance:", wsBalanceAfter);
    console.log("WS profit from arbitrage2:", wsProfit);

    return wsProfit;
  }

  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external override {
    SwapCallbackData memory decoded = abi.decode(data, (SwapCallbackData));
    require(msg.sender == decoded.poolAddress, "Invalid pool caller");

    uint256 amountToPay = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

    IERC20(decoded.tokenIn).transfer(msg.sender, amountToPay);
  }

  receive() external payable {}
}

contract ArbitrageTest is Script {
  function run() public {
    vm.startBroadcast();

    ArbitrageContract arb = new ArbitrageContract();

    // Send ETH to contract to perform WETH deposit inside it
    payable(address(arb)).transfer(10 ether);

    int256 profit = arb.executeArbitrage2();
    console.log("Profit (in WETH units):", profit);

    require(profit > 10 ** 20, "end of test");

    vm.stopBroadcast();
  }
}
