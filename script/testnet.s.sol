// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
// import {Counter} from "../src/Counter.sol";

contract AnvilScript is Script {

  function setUp() public {}

  function run() public {
    vm.startBroadcast();


    vm.stopBroadcast();
  }
}
