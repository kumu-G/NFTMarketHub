// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyERC20Token} from "../src/MyERC20Token.sol";

contract MyERC20TokenScript is Script {
    MyERC20Token public mytoken;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAccountAddress = vm.envAddress("ACCOUNT_ADDRESS");
        vm.startBroadcast(deployerPrivateKey);

        mytoken = new MyERC20Token(deployerAccountAddress);
        console.log("deployerAccountAddress :", deployerAccountAddress);
        console.log("MyERC20Token deployed to:", address(mytoken));

        vm.stopBroadcast();
    }
}
