// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyERC721Token} from "../src/MyERC721Token.sol";

contract MyERC721TokenTest is Test {
    MyERC721Token public my721token;

    address public owner = address(0x1);
    address public user = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        my721token = new MyERC721Token(owner);

        vm.startPrank(owner);

        my721token.safeMint(user, "https://ipfs.io/ipfs/QmWbMwzP9P7nkn5YnxC3YRwEjvYgJ9YUu2v9n1wZGK5K8s");
        my721token.safeMint(user2, "https://ipfs.io/ipfs/QmWbMwzP9P7nkn5YnxC3YRwEjvYgJ9YUu2v9n1wZGK5K8s");

        vm.stopPrank();
    }

    function testMint() public {
        vm.startPrank(owner);

        my721token.safeMint(user, "https://ipfs.io/ipfs/QmWbMwzP9P7nkn5YnxC3YRwEjvYgJ9YUu2v9n1wZGK5K8s");
        vm.stopPrank();
        assertEq(my721token.balanceOf(user), 2);
    }
}
