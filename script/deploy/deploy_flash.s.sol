// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { UniswapV3FlashSwap } from "@/UniswapV3FlashSwap.sol";

contract DeployFlash is Script {
  UniswapV3FlashSwap _UniswapV3FlashSwap;
  function run() external {
    vm.startBroadcast();

    _UniswapV3FlashSwap = new UniswapV3FlashSwap();

    vm.stopBroadcast();
  }
}
