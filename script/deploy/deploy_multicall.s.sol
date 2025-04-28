// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import { Multicall } from "@/utils/Multicall.sol";

contract DeployMulticall is Script {
  Multicall _multicall;
  function run() external {
    vm.startBroadcast();

    _multicall = new Multicall();

    vm.stopBroadcast();
  }
}
