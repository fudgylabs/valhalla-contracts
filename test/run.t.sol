// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Valhalla } from "../src/Valhalla.sol";
import { ValhallaOracle, IPool } from "../src/ValhallaOracle.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IPair } from "./interfaces/IPair.sol";
import { IRouter } from "./interfaces/IRouter.sol";
import { IWETH } from "./interfaces/IWETH.sol";

contract CounterTest is Test {
  // SWAPX
  address public constant ROUTER = 0xF5F7231073b3B41c04BA655e1a7438b1a7b29c27;
  address public constant FACTORY = 0xF5F7231073b3B41c04BA655e1a7438b1a7b29c27;

  // CONFIG
  string constant RPC_URL = "https://sonic-rpc.publicnode.com";

  // USERS
  address public constant DEPLOYER = address(uint160(uint256(keccak256("DEPLOYER"))));
  address public constant OPERATOR = address(uint160(uint256(keccak256("OPERATOR"))));

  // POOLS
  address constant OS = 0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794;     // 70k   -> 10000/86400
  address constant SCUSD = 0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE;  // 84.7k -> 12100/86400
  address constant SCETH = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812;  // 54.6k -> 7800/86400
  address constant SCBTC = 0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd;  // 54.6k -> 7800/86400
  address constant STS = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955;    // 24.5k -> 3500/86400
  address constant SHADOW = 0x3333b97138D4b086720b5aE8A7844b1345a33333; // 24.5k -> 3500/86400
  address constant X33 = 0x3333111A391cC08fa51353E9195526A70b333333;    // 19.6k -> 2800/86400
  address constant BOO = 0x7A0C53F7eb34C5BC8B01691723669adA9D6CB384;    // 19.6k -> 2800/86400
  address constant EQUAL = 0xddF26B42C1d903De8962d3F79a74a501420d5F19;  // 19.6k -> 2800/86400
  address constant EGGS = 0xf26Ff70573ddc8a90Bd7865AF8d7d70B8Ff019bC;   // 17.5k -> 2500/86400
  address constant ANON = 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C;   // 10.5k -> 1500/86400
  address constant DERP = 0xe920d1DA9A4D59126dC35996Ea242d60EFca1304;   // 8.05k -> 1150/86400
  address constant GOGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564;  // 7k    -> 1000/86400
  address constant HEDGY = 0x6fB9897896Fe5D05025Eb43306675727887D0B7c;  // 7k    -> 1000/86400
  address constant OIL = 0x31E2eed04a62b232DA964A097D8C171584e3C3Bd;    // 9.8k  -> 1400/86400
  address constant BRUSH = 0xE51EE9868C1f0d6cd968A8B8C8376Dc2991BFE44;  // 9.8k  -> 1400/86400



  // CONTRACTS
  Valhalla public _valhalla;
  address public _pair;
  ValhallaOracle public _valhallaOracle;

  function setUp() public {
    vm.createSelectFork(RPC_URL);

    vm.deal(DEPLOYER, 50 ether);

    vm.prank(0xa3c0eCA00D2B76b4d1F170b0AB3FdeA16C180186); // OS Vault address
    IWETH(payable(OS)).mint(DEPLOYER, 50 ether);

    vm.startPrank(DEPLOYER);
    _valhalla = new Valhalla();
    _valhalla.approve(ROUTER, 49 ether);
    IWETH(payable(OS)).approve(ROUTER, 49 ether);

    (uint amountA, uint amountB, uint liquidity) = IRouter(payable(ROUTER)).addLiquidity(
      address(_valhalla),
      OS,
      true,
      49 ether,
      49 ether,
      0,
      0,
      DEPLOYER,
      block.timestamp + 3600
    );
    _pair = IRouter(payable(ROUTER)).pairFor((address(_valhalla)), OS, true);
    vm.assertEq(amountA, 49 ether);
    vm.assertEq(amountB, 49 ether);
    vm.assertApproxEqRel(liquidity, 49 ether, 10000);

    _valhallaOracle = new ValhallaOracle(IPool(_pair));

    vm.stopPrank();
  }

  function test_FetchContractData() public view {
    bytes memory routerCode = address(ROUTER).code;
    bytes memory factoryCode = address(FACTORY).code;
    bytes memory osCode = address(OS).code;

    console.log("Router code size:");
    console.logUint(routerCode.length);
    console.log("Factory code size:");
    console.logUint(factoryCode.length);
    console.log("OS code size:");
    console.logUint(osCode.length);

    // Assert that we have contract code
    assertTrue(routerCode.length > 0, "No code at Router address");
    assertTrue(factoryCode.length > 0, "No code at Factory address");
    assertTrue(osCode.length > 0, "No code at OS address");
  }

  // function testFuzz_SetNumber(uint256 x) public {
  //     counter.setNumber(x);
  //     assertEq(counter.number(), x);
  // }
}
