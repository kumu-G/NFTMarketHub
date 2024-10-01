// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MyERC20Token} from "../src/MyERC20Token.sol";
import {SigUtils} from "../src/SigUtils.sol";

contract MyERC20TokenTest is Test {
    MyERC20Token public mytoken;
    SigUtils internal sigUtils;

    // address public owner = address(0x1);

    address public alice = address(0x2);
    address public bob = address(0x3);
    address public charlie = address(0x4);

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        mytoken = new MyERC20Token(owner);

        sigUtils = new SigUtils(mytoken.DOMAIN_SEPARATOR());

        vm.startPrank(owner);
        mytoken.mint(alice, 100);
        mytoken.mint(bob, 200);
        mytoken.mint(charlie, 300);

        mytoken.mint(owner, 1e18);
        vm.stopPrank();
    }

    function testBalanceOf() public view {
        assertEq(mytoken.balanceOf(owner), 1e18);
        assertEq(mytoken.balanceOf(alice), 100);
        assertEq(mytoken.balanceOf(bob), 200);
        assertEq(mytoken.balanceOf(charlie), 300);
    }

    function testName() public view {
        assertEq(mytoken.name(), "MyERC20Token");
    }

    function testSymbol() public view {
        assertEq(mytoken.symbol(), "MTKERC20");
    }

    function testDecimals() public view {
        assertEq(mytoken.decimals(), 18);
    }

    function testMint() public {
        vm.startPrank(owner);
        mytoken.mint(owner, 1000e18);
        assertEq(mytoken.balanceOf(owner), 1001e18);
        vm.stopPrank();
    }

    function testTransfer() public {
        vm.startPrank(alice);
        mytoken.transfer(bob, 50);
        assertEq(mytoken.balanceOf(alice), 50);
        assertEq(mytoken.balanceOf(bob), 250);
        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(alice);
        mytoken.approve(bob, 50);
        assertEq(mytoken.allowance(alice, bob), 50);
        vm.stopPrank();
    }

    function test_Permit() public {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: owner, spender: spender, value: 1e18, nonce: 0, deadline: 1 days});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        mytoken.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);

        assertEq(mytoken.allowance(owner, spender), 1e18);
        assertEq(mytoken.nonces(owner), 1);
    }

    function testFailRevert_ExpiredPermit() public {
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: 1e18,
            nonce: mytoken.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.warp(1 days + 1 seconds); // fast forward one second past the deadline

        // vm.expectRevert("PERMIT_DEADLINE_EXPIRED");
        vm.expectRevert("ERC2612ExpiredSignature");
        mytoken.permit(permit.owner, permit.spender, permit.value, permit.deadline, v, r, s);
    }
}
