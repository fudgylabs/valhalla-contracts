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
  address public constant OS = 0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794; // pair with this

  // CONFIG
  string constant RPC_URL = "https://sonic-rpc.publicnode.com";

  // USERS
  address public constant DEPLOYER = address(uint160(uint256(keccak256("DEPLOYER"))));
  address public constant OPERATOR = address(uint160(uint256(keccak256("OPERATOR"))));

  // POOLS
  

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

  function test_FetchContractData() public {
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
