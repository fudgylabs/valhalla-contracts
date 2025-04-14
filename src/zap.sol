// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRouter.sol";

contract VALZapIn is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // IMMUTABLE VARIABLES
  address public immutable VAL_TOKEN;
  address public immutable OS_TOKEN;
  address public immutable SWAP_ROUTER;

  // EVENTS
  event ZapIn(address indexed user, address tokenIn, uint amountIn);

  constructor(
    address _VAL_TOKEN,
    address _OS_TOKEN,
    address _SWAP_ROUTER
  ) Ownable() {
    VAL_TOKEN = _VAL_TOKEN;
    OS_TOKEN = _OS_TOKEN;
    SWAP_ROUTER = _SWAP_ROUTER;
  }

  // EXTERNAL FUNCTIONS
  function zapInToken(address _tokenIn, uint _tokenAmount) external nonReentrant {
    require(
      _tokenIn == VAL_TOKEN || _tokenIn == OS_TOKEN,
      "Only VAL or OS tokens accepted"
    );

    // Transfer tokens from user
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _tokenAmount);

    // Get the optimal amounts for adding liquidity
    (uint amount0, uint swapAmount) = _getOptimalAmounts(_tokenIn, _tokenAmount);

    // Perform the swap if needed
    if (swapAmount > 0) {
      address _tokenOut = _tokenIn == VAL_TOKEN ? OS_TOKEN : VAL_TOKEN;
      _swapExactTokensForTokens(swapAmount, _tokenIn, _tokenOut, address(this));
    }

    _addLiquidity();

    // Return any remaining tokens to user
    uint remainingVALBalance = IERC20(VAL_TOKEN).balanceOf(address(this));
    if (remainingVALBalance > 0) {
      if (_tokenIn == OS_TOKEN) {
        // Convert VAL to OS if sender sent OS
        _swapExactTokensForTokens(remainingVALBalance, VAL_TOKEN, OS_TOKEN, msg.sender);
      } else {
        // Return any remaining tokens to user
        IERC20(VAL_TOKEN).safeTransfer(msg.sender, remainingVALBalance);
      }
    }

    uint remainingOSBalance = IERC20(OS_TOKEN).balanceOf(address(this));
    if (remainingOSBalance > 0) {
      if (_tokenIn == VAL_TOKEN) {
        // Convert OS to VAL if sender sent VAL
        _swapExactTokensForTokens(remainingOSBalance, OS_TOKEN, VAL_TOKEN, msg.sender);
      } else {
        // Return any remaining tokens to user
        IERC20(OS_TOKEN).safeTransfer(msg.sender, remainingOSBalance);
      }
    }

    emit ZapIn(msg.sender, _tokenIn, _tokenAmount);
  }

  // INTERNAL FUNCTIONS
  function _addLiquidity() internal {
    // Add liquidity
    uint balance0 = IERC20(VAL_TOKEN).balanceOf(address(this));
    uint balance1 = IERC20(OS_TOKEN).balanceOf(address(this));

    IERC20(VAL_TOKEN).approve(SWAP_ROUTER, balance0);
    IERC20(OS_TOKEN).approve(SWAP_ROUTER, balance1);

    (, , uint liquidity) = IRouter(payable(SWAP_ROUTER)).addLiquidity(
      VAL_TOKEN,
      OS_TOKEN,
      true,
      balance0,
      balance1,
      0,
      0,
      msg.sender,
      block.timestamp
    );
  }

  function _getOptimalAmounts(
    address _tokenIn,
    uint _tokenAmount
  ) internal view returns (uint amount0, uint swapAmount) {
    // Get token order from pair
    address token0 = VAL_TOKEN;
    address token1 = OS_TOKEN;

    // For stable pools, calculate the optimal ratio
    uint out0 = _tokenIn == token0 ? _tokenAmount / 2 : 0;
    uint out1 = _tokenIn == token1 ? _tokenAmount / 2 : 0;

    // Get expected output for the swap
    if (_tokenIn == token0) {
      uint[] memory amounts = IRouter(payable(SWAP_ROUTER)).getAmountsOut(
        _tokenAmount / 2,
        _getRoutes(token0, token1)
      );
      out1 = amounts[amounts.length - 1];
    } else {
      uint[] memory amounts = IRouter(payable(SWAP_ROUTER)).getAmountsOut(
        _tokenAmount / 2,
        _getRoutes(token1, token0)
      );
      out0 = amounts[amounts.length - 1];
    }

    // Quote optimal amounts
    (uint amountA, uint amountB, ) = IRouter(payable(SWAP_ROUTER)).quoteAddLiquidity(
      token0,
      token1,
      true,
      out0,
      out1
    );

    // Calculate optimal ratio with decimal adjustment
    // VAL is 1e18, OS is 1e6
    if (_tokenIn == token0) {
      // If input is VAL
      uint ratio = (((out0 * 1e18) / out1) * amountB) / amountA;
      amount0 = (_tokenAmount * 1e18) / (ratio + 1e18);
      swapAmount = _tokenAmount - amount0;
    } else {
      // If input is OS
      uint ratio = (((out0 * 1e6) / out1) * amountB) / amountA;
      swapAmount = (_tokenAmount * 1e6) / (ratio + 1e6);
      amount0 = _tokenAmount - swapAmount;
    }
  }

  function _getRoutes(
    address _tokenIn,
    address _tokenOut
  ) internal pure returns (IRouter.route[] memory) {
    IRouter.route[] memory routes = new IRouter.route[](1);
    routes[0] = IRouter.route({ from: _tokenIn, to: _tokenOut, stable: true });
    return routes;
  }

  function _swapExactTokensForTokens(
    uint _amountIn,
    address _tokenIn,
    address _tokenOut,
    address _to
  ) internal {
    IERC20 tokenIn = IERC20(_tokenIn);
    tokenIn.approve(address(SWAP_ROUTER), _amountIn);

    IRouter.route[] memory routes = _getRoutes(_tokenIn, _tokenOut);

    IRouter(payable(SWAP_ROUTER)).swapExactTokensForTokens(_amountIn, 0, routes, _to, block.timestamp);
  }

  // EMERGENCY FUNCTIONS
  function withdraw(address _token) external onlyOwner {
    if (_token == address(0)) {
      (bool success, ) = address(owner()).call{ value: address(this).balance }("");
    }
    IERC20 token = IERC20(_token);
    token.transfer(owner(), token.balanceOf(address(this)));
  }
}
