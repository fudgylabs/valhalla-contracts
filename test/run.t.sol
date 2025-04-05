// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Valhalla } from "../src/Valhalla.sol";
import { ValhallaOracle, IPool } from "../src/ValhallaOracle.sol";
import { IFactory } from "./interfaces/IFactory.sol";
import { IPair } from "./interfaces/IPair.sol";
import { IRouter } from "./interfaces/IRouter.sol";

contract CounterTest is Test {
  // CONFIG
  string constant RPC_URL = "YOUR_RPC_URL"; // Replace with your RPC URL
    
    

  // SWAPX
  address constant public ROUTER = 0xF5F7231073b3B41c04BA655e1a7438b1a7b29c27;
  address constant public FACTORY = 0xF5F7231073b3B41c04BA655e1a7438b1a7b29c27;
  address constant public WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;

  IRouter router;
  IFactory factory;

  // USERS
  address constant public OPERATOR = address(uint160(uint256(keccak256("OPERATOR"))));
  address constant public PAIR = address(uint160(uint256(keccak256("PAIR")))); // need to deploy




  // CONTRACTS
  Valhalla public _valhalla;
  ValhallaOracle public _valhallaOracle;

  function setUp() public {
    vm.deal(OPERATOR, 50 ether);

    vm.startPrank(OPERATOR);
    _valhalla = new Valhalla();
    _valhallaOracle = new ValhallaOracle(IPool(PAIR));

    vm.stopPrank();
  }

  function test_Init() public {
    vm.prank(OPERATOR);
    address(_valhalla).call{value: 1 ether}("");
  }

  // function testFuzz_SetNumber(uint256 x) public {
  //     counter.setNumber(x);
  //     assertEq(counter.number(), x);
  // }
}
