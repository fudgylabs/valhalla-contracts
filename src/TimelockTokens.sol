// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./owner/Operator.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TimelockTokens is Operator {
  uint256 public releaseTime;

  constructor() {
    releaseTime = block.timestamp;
  }

  modifier isUnlocked() {
    require(releaseTime < block.timestamp, "timelock is running");
    _;
  }

  function recoverToken(address token) public isUnlocked onlyOperator(){
    uint256 balance = IERC20(payable(token)).balanceOf(address(this));
    IERC20(payable(token)).transferFrom(address(this), msg.sender, balance);
  }

  function setLockTime(uint256 newTimestamp) public onlyOperator {
    require(newTimestamp > releaseTime, "newTimestamp is too small");
    releaseTime = newTimestamp;
  }

  function extendLockTime(uint256 amount) public onlyOperator {
    releaseTime = releaseTime + amount;
  }
}