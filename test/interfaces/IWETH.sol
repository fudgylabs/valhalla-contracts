// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
  // Custom errors
  error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
  error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
  error ERC20InvalidApprover(address approver);
  error ERC20InvalidReceiver(address receiver);
  error ERC20InvalidSender(address sender);
  error ERC20InvalidSpender(address spender);
  error ERC20InvalidZeroDeposit();
  error ERC20WithdrawFailed(address recipient, uint256 value);

  // Events
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Deposit(address indexed account, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Withdrawal(address indexed account, uint256 value);

  // Standard ERC20 functions
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function mint(address _account, uint256 _amount) external;


  // Wrapped token specific functions
  function deposit() external payable;
  function depositFor(address account) external payable returns (bool);
  function withdraw(uint256 value) external;
  function withdrawTo(address account, uint256 value) external returns (bool);

  // Fallback function to handle direct deposits
  fallback() external payable;
  receive() external payable;
}
