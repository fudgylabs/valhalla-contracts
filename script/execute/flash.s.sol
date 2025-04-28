// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
pragma abicoder v2;

import { Script, console } from "forge-std/Script.sol";
import {
    UniswapV3FlashSwap,
    IUniswapV3Pool,
    ISwapRouter02,
    IERC20,
    IWETH
} from "@/UniswapV3FlashSwap.sol";

address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
address constant ANON = 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C;
address constant SWAP_ROUTER_02 = 0x9282a6C62932431B127753C1CD2ac4F6cC4CFD49;
address constant ANON_WETH_POOL_3000 = 0x297000941c155962B04760EcAeAA422757F20bc1; // some anon pool
address constant ANON_WETH_POOL_1000 = 0x267FB0fC7694AF30fFBCD3c27Ce7497A7Db73616; // some other anon pool
uint24 constant FEE_0 = 3000;
uint24 constant FEE_1 = 10000;

contract UniswapV3FlashTest is Script {
    IERC20 private constant anon = IERC20(ANON);
    IWETH private constant weth = IWETH(WS);
    ISwapRouter02 private constant router = ISwapRouter02(SWAP_ROUTER_02);
    IUniswapV3Pool private constant pool0 = IUniswapV3Pool(ANON_WETH_POOL_3000);
    IUniswapV3Pool private constant pool1 = IUniswapV3Pool(ANON_WETH_POOL_1000);
    UniswapV3FlashSwap private flashSwap = UniswapV3FlashSwap(0xca63360849bD8Ae6FB00B70989e386982d74c18e);

    uint256 private constant ANON_AMOUNT_IN = 1 * 1e18;

    function setUp() public {}

    function run() public {
    vm.startBroadcast();
    uint256 bal0 = anon.balanceOf(msg.sender);
    flashSwap.flashSwap({
        pool0: address(pool0),
        fee1: FEE_1,
        tokenIn: ANON,
        tokenOut: WS,
        amountIn: ANON_AMOUNT_IN
    });
    uint256 bal1 = anon.balanceOf(msg.sender);
    uint256 profit = bal1 - bal0;
    // assertGt(profit, 0, "profit = 0");
    require(profit > 0, "profit <= 0");
    vm.stopBroadcast();
  }
}
