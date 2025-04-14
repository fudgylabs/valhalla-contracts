// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script, console } from "forge-std/Script.sol";
import { Valhalla } from "../../src/Valhalla.sol";
import { Ragnarok } from "../../src/distribution/Ragnarok.sol";
import { ValhallaOracle } from "../../src/ValhallaOracle.sol";

import "../../src/interfaces/IWETH.sol";
import "../../src/interfaces/IRouter.sol";
import "../../src/interfaces/IPool.sol";
import "../../src/interfaces/IERC20.sol";
import { Token } from "../../src/ERC20.sol";
// deal tokens to deployer address
// deploy valhalla
// deploy pair with router
// deal OS to deployer
// add liquidity to the the router
// import {Counter} from "../src/Counter.sol";

contract AnvilScript is Script {
  Valhalla public _valhalla;
  Ragnarok public _ragnarok;
  ValhallaOracle public _valhallaOracle;
  address public _pair;

  // SHADOW
  address public constant SHADOW_ROUTER = 0x1D368773735ee1E678950B7A97bcA2CafB330CDc;
  address public constant SHADOW_FACTORY = 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8;

  // CONFIG
  string constant RPC_URL = "http://127.0.0.1:8545";

  // USERS
  address public constant DEPLOYER = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
  address public constant OPERATOR = address(uint160(uint256(keccak256("OPERATOR"))));

  address public TEMP_VAL_OS_LP;
  address constant OS = 0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794; // 70k   -> 10000/86400
  address constant SCUSD = 0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE; // 84.7k -> 12100/86400
  address constant SCETH = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812; // 54.6k -> 7800/86400
  address constant SCBTC = 0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd; // 54.6k -> 7800/86400
  address constant STS = 0xE5DA20F15420aD15DE0fa650600aFc998bbE3955; // 24.5k -> 3500/86400
  address constant SHADOW = 0x3333b97138D4b086720b5aE8A7844b1345a33333; // 24.5k -> 3500/86400
  address constant X33 = 0x3333111A391cC08fa51353E9195526A70b333333; // 19.6k -> 2800/86400
  address constant BOO = 0x7A0C53F7eb34C5BC8B01691723669adA9D6CB384; // 19.6k -> 2800/86400
  address constant EQUAL = 0xddF26B42C1d903De8962d3F79a74a501420d5F19; // 19.6k -> 2800/86400
  address constant EGGS = 0xf26Ff70573ddc8a90Bd7865AF8d7d70B8Ff019bC; // 17.5k -> 2500/86400
  address constant ANON = 0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C; // 10.5k -> 1500/86400
  address constant DERP = 0xe920d1DA9A4D59126dC35996Ea242d60EFca1304; // 8.05k -> 1150/86400
  address constant GOGLZ = 0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564; // 7k    -> 1000/86400
  address constant HEDGY = 0x6fB9897896Fe5D05025Eb43306675727887D0B7c; // 7k    -> 1000/86400
  address constant OIL = 0x31E2eed04a62b232DA964A097D8C171584e3C3Bd; // 9.8k  -> 1400/86400
  address constant BRUSH = 0xE51EE9868C1f0d6cd968A8B8C8376Dc2991BFE44; // 9.8k  -> 1400/86400

  address public _token;

  function setUp() public {
    // vm.startPrank(DEPLOYER);
    // _valhalla = new Valhalla();
    // vm.stopPrank();
  }

  function run() public {
    vm.createSelectFork(RPC_URL);

    vm.startBroadcast(DEPLOYER);
    // address[16] memory targets = [
    //   OS,
    //   SCUSD,
    //   SCETH,
    //   SCBTC,
    //   STS,
    //   SHADOW,
    //   X33,
    //   BOO,
    //   EQUAL,
    //   EGGS,
    //   ANON,
    //   DERP,
    //   GOGLZ,
    //   HEDGY,
    //   OIL,
    //   BRUSH
    // ];

    // for (uint256 i = 0; i < targets.length; i++) {
    //   Token(targets[i]).mintTo(DEPLOYER, 50 ether);
    // }


    fetchContractData(OS);

    Token(OS).mintTo(DEPLOYER, 50 ether);


    vm.stopBroadcast();
  }

  function fetchContractData(address contract_) public view {
    bytes memory contractCode = contract_.code;

    console.log("code size:");
    console.logUint(contractCode.length);

  }

}
