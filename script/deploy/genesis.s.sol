// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { Valhalla } from "../../src/Valhalla.sol";
import { Ragnarok } from "../../src/distribution/Ragnarok.sol";
import { VALZapIn } from "../../src/zap.sol";
import { IPairFactory } from "../../src/interfaces/IPairFactory.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Boardroom } from "../../src/Boardroom.sol";
import { TimelockTokens } from "../../src/TimelockTokens.sol";
import { IPair } from "../../src/interfaces/IPair.sol";
import { IRouter } from "../../src/interfaces/IRouter.sol";


// import "../src/interfaces/IRouter.sol";
// import "../src/interfaces/IPool.sol";

contract GenesisScript is Script {
  Valhalla public _valhalla;
  Ragnarok public _ragnarok;
  address public _pair;
  VALZapIn public _zap;
  Boardroom public _boardroom;
  TimelockTokens public _timelockTokens;

  // SHADOW
  address public constant SHADOW_ROUTER = 0x1D368773735ee1E678950B7A97bcA2CafB330CDc;
  address public constant SHADOW_FACTORY = 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8;
  address public constant SHADOW_VOTER = 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8;
  address public constant SHADOW_PAIR_FACTORY = 0x2dA25E7446A70D7be65fd4c053948BEcAA6374c8;

  // USERS
  address public constant DEPLOYER = 0x04301b0c3bC192C28DD3CAF345C4aE6E979EC040; // actual deployer
  address public constant DEVFUND = 0x9bdEFaA23377f54A26e3bfb27C73c525C8fc8b98; // actual devfund (new)

  address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
  address constant OS = 0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794; // 70k   -> 10000/86400

  address constant VAL = 0xB1550fD0fAdaf3c71AD585677AA3d1fd9CF7033f;
  address constant VALPAIR = 0xAC4679fdDA27995bbDab65A36670630b60C07EDd;

  function setUp() public {}

  function run() public {
    vm.startBroadcast();

    // deploy genesis
    _ragnarok = new Ragnarok(
      VAL,
      DEVFUND,
      1745402400,
      SHADOW_VOTER
    );

    _ragnarok.add(0.237268519 ether, 0, IERC20(0xAC4679fdDA27995bbDab65A36670630b60C07EDd), false, 0); 

    vm.stopBroadcast();
  }
}
