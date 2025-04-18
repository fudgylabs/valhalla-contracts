// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBasisAsset {
  function mint(address recipient, uint256 amount) external returns (bool);

  function burn(uint256 amount) external;

  function burnFrom(address from, uint256 amount) external;

  function isOperator() external returns (bool);

  function operator() external view returns (address);

  function transferOperator(address newOperator_) external;
}
