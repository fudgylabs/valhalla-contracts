// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test, console } from "forge-std/Test.sol";
import { Valhalla } from "@/Valhalla.sol";
import { ValhallaOracle, IPool } from "@/ValhallaOracle.sol";
import { IFactory } from "@/interfaces/IFactory.sol";
import { IPair } from "@/interfaces/IPair.sol";
import { IRouter } from "@/interfaces/IRouter.sol";
import { IWETH } from "@/interfaces/IWETH.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ragnarok } from "@/distribution/Ragnarok.sol";
import { IPairFactory } from "@/interfaces/IPairFactory.sol"; 
import { VALZapIn } from "@/zap.sol";
import { Boardroom } from "@/Boardroom.sol";
import { TimelockTokens } from "@/TimelockTokens.sol";
import { Operator } from "@/owner/Operator.sol";

contract GovernanceRecoverUnsupportedTest is Test {
  address public constant DEPLOYER = address(uint160(uint256(keccak256("DEPLOYER"))));
  address public constant OPERATOR = address(uint160(uint256(keccak256("OPERATOR"))));
  address public constant USER = address(uint160(uint256(keccak256("USER"))));
  address public constant DEVFUND = address(uint160(uint256(keccak256("DEVFUND"))));
  

  address public _erc20;
  Ragnarok public _ragnarok;

  function setUp() public {
    initialTimestamp = block.timestamp;
    vm.deal(DEPLOYER, 1000 ether);
    vm.deal(USER, 1000 ether);
  }

// function governanceRecoverUnsupported(IERC20 _token, uint256 amount) external {
//     if (block.timestamp < poolEndTime + 7 days) {
//       // do not allow to drain tokens if less than 7 days after pool ends
//       uint256 length = poolInfo.length;
//       for (uint256 pid = 0; pid < length; ++pid) {
//         PoolInfo storage pool = poolInfo[pid];
//         require(_token != pool.token, "token cannot be pool token");
//       }
//     }

//     _token.safeTransfer(devFund, amount);
  }

