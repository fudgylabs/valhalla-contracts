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

contract ValAndGenesisScript is Script {
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
  address public constant DEVFUND = 0x43b9e3d7Fbc5c1c32F9aAFB31a443CE559D805e9; // actual devfund

  address constant WS = 0x039e2fB66102314Ce7b64Ce5Ce3E5183bc94aD38;
  address constant OS = 0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794; // 70k   -> 10000/86400

  function setUp() public {}

  function run() public {
    vm.startBroadcast();

    // mint valhalla
    _valhalla = new Valhalla();

    // deploy genesis
    _ragnarok = new Ragnarok(
      address(_valhalla),
      DEVFUND,
      1744974000,
      SHADOW_VOTER
    );

    _boardroom = new Boardroom();

    // distribute valhalla
    _valhalla.distributeReward(DEVFUND, address(_ragnarok));

    // create VAL-OS LP pool
    _pair = IPairFactory(SHADOW_PAIR_FACTORY).createPair(address(_valhalla), OS, true);

    // add LP pool to genesis
    // add(0.237268519 ether, 0, IERC20(address(0)), false, 0); // VAL-OS LP 143.5k (20500/86400)
    // _ragnarok.add(0.237268519 ether, 0, IERC20(_pair), false, 0);
    _ragnarok.add(0.237268519 ether, 0, IERC20(_pair), false, 0); 

    // deploy zap
    _zap = new VALZapIn(address(_valhalla), OS, SHADOW_ROUTER);

    _timelockTokens = new TimelockTokens();

    // (uint amountA, uint amountB, uint liquidity) = IRouter(payable(SHADOW_ROUTER)).addLiquidity(
    //   address(_valhalla),
    //   OS,
    //   true,
    //   30 ether,
    //   30 ether,
    //   0,
    //   0,
    //   DEPLOYER,
    //   block.timestamp + 600
    // );
    // require(amountA > 0, "amountA liquidity not changed");
    // require(amountB > 0, "amountB liquidity not changed");

    // uint256 pairBalance = IERC20(_pair).balanceOf(msg.sender);
    // IPair(_pair).transferFrom(msg.sender, address(_timelockTokens), pairBalance);

    // uint256 pairBalance2 = IERC20(_pair).balanceOf(address(_timelockTokens));
    // require(pairBalance2 > 0, "transfer balance to lock failed");

    // // transfer peg ownership to boardroom
    // _valhalla.transferOperator(address(_boardroom));

    // // renounce genesis ownership
    // _ragnarok.setOperator(address(0));

    vm.stopBroadcast();
  }
}
