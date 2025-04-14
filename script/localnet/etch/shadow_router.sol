// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.20;

// import "forge-std/Script.sol";
// import "../src/Valhalla.sol"; // your contract

// contract AnvilScript is Script {
//     address constant TARGET = 0x1234567890123456789012345678901234567890;

//     function run() public {
//         vm.startBroadcast();

//         Valhalla deployed = new Valhalla();
//         bytes memory runtime = address(deployed).code;
//         vm.etch(TARGET, runtime);

//         console.log("Etched Valhalla runtime into:", TARGET);

//         vm.stopBroadcast();
//     }

//     function swapOSForToken(address targetToken, uint256 amount, bool stable) internal {
//         // Create route for the swap
//         IRouter.route[] memory path = new IRouter.route[](1);
//         path[0] = IRouter.route({ from: OS, to: targetToken, stable: stable });

//         // Approve spending
//         IERC20(payable(OS)).approve(SHADOW_ROUTER, amount);

//         // Execute swap
//         IRouter(payable(SHADOW_ROUTER)).swapExactTokensForTokens(
//         amount,
//         0, // Min amount out (0 for testing)
//         path,
//         DEPLOYER,
//         block.timestamp + 3600
//     );
//   }
// }
