// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {
  constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
    _mint(msg.sender, 50 ether);
  } 

  function mintTo(address to, uint256 amount) public {
    _mint(to, amount);
  }
}