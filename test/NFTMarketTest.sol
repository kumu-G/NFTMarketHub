// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console, console2} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyERC20Token} from "../src/MyERC20Token.sol";
import {MyERC721Token} from "../src/MyERC721Token.sol";

contract NFTMarketTest is Test {
    MyERC20Token public mytoken;
    MyERC721Token public mynft;
    NFTMarket public nftmarket;

    address public owner = address(0x1);
    address public buyer = address(0x2);

    event Deal(address seller, address buyer, uint256 tokenId, uint256 price);
    event NewOrder(address seller, uint256 tokenId, uint256 price);

    function setUp() public {
        // 1. 部署 ERC20 合约
        mytoken = new MyERC20Token(owner);
        // 2. 部署 ERC721 合约
        mynft = new MyERC721Token(owner);
        // 3. 使用 ERC20 合约地址 和 ERC721 合约地址作为初始化参数部署 NFTMarket 合约
        nftmarket = new NFTMarket(address(mytoken), address(mynft));

        vm.startPrank(owner); // 默认是测试合约
        // 4. 账户1 owner 在 ERC20 合约上 mint token
        vm.label(owner, "ERC20owner");
        mytoken.mint(owner, 100e18);
        // 5. 账户1 owner 在 ERC721 合约上 safeMint NFT
        mynft.safeMint(owner, "https://ipfs.io/ipfs/QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8");

        vm.stopPrank();
    }

    function testTokenBalance() public view {
        assertEq(mytoken.balanceOf(owner), 100e18, "owner balance is not 100e18");

        assertEq(mytoken.balanceOf(buyer), 0, "buyer balance is not 0");
        assertEq(mytoken.balanceOf(address(nftmarket)), 0, "market balance is not 0");
    }

    function testNFTBalance() public view {
        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.balanceOf(buyer), 0, "buyer nft balance is not 0");
    }

    function testTransferToken() public {
        vm.prank(owner);
        vm.label(buyer, "Buyer");
        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);
        assertEq(mytoken.balanceOf(owner), 90e18);
    }

    // 6. 账户1 在 ERC721 合约上调用 setApprovalForAll 授权 NFTMarket 合约，参数为 NFTMarket 合约地址和 true
    function testSetApprovalForAll() public {
        vm.prank(owner);
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true);
    }

    // 7. 账户1 在 NFTMarket 合约上调用 listNFT 挂单（上架 tokenId 为 0 的 NFT）
    function testListNFT() public {
        vm.startPrank(owner);
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true);
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");

        // 测试事件 NewOrder
        // event NewOrder(address seller, uint256 tokenId, uint256 price);
        vm.expectEmit(true, true, true, true);
        emit NewOrder(owner, 0, 1e18);

        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true);

        assertEq(nftmarket.getOrderLength(), 1);
        assertEq(mynft.getApproved(0), address(0));

        vm.stopPrank();
    }

    function testIsListed() public {
        vm.startPrank(owner);
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true);
        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true);

        vm.stopPrank();
    }

    // 8. 账户1 在 ERC20 合约上调用 transfer 转移 10个 ERC20 token 给 账户2
    function testTransferTokenToBuyer() public {
        vm.prank(owner);
        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);
        assertEq(mytoken.balanceOf(owner), 90e18);
    }

    // 9. 账户2 在 ERC20 合约上调用 approve 方法授权 NFTMarket 合约使用1个ERC20token，参数为 NFTMarket 合约地址 和数量 1,000,000,000,000,000,000
    function testApprove() public {
        vm.prank(buyer);
        mytoken.approve(address(nftmarket), 1e18);
        assertEq(mytoken.allowance(buyer, address(nftmarket)), 1e18);
    }

    // 10. 账户2 在 NFTMarket 合约上调用 buyNFT 购买 tokenId 为 0 的 NFT
    function testBuyNFT() public {
        // 查询NFT
        vm.startPrank(owner);

        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");

        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);

        // 授权并上架
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true, "owner nft is not approved for all");
        // NFT的拥有者才有权限上架
        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true, "nft market is not listed");
        vm.stopPrank();

        // 购买
        vm.startPrank(buyer);
        mytoken.approve(address(nftmarket), 1e18);
        assertEq(mytoken.allowance(buyer, address(nftmarket)), 1e18, "buyer token allowance is not 1e18");
        //
        nftmarket.buyNFT(0);
        assertEq(mynft.ownerOf(0), buyer, "nft owner is not buyer");
        vm.stopPrank();
    }

    // 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
    function testFailListNFT() public {
        vm.startPrank(owner);
        vm.expectRevert("Reason: ERC721InsufficientApproval");
        nftmarket.listNFT(0, 1e18);
        vm.stopPrank();
    }

    // 测试上架成功
    function testListNFTSuccess() public {
        vm.startPrank(owner);
        // 判断NFT
        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");

        // https://stackoverflow.com/questions/63252057/how-to-use-bytestouint-function-in-solidity-the-one-with-assembly
        // 上架
        mynft.safeTransferFrom(
            owner, address(nftmarket), 0, "0x0000000000000000000000000000000000000000000000000001c6bf52634000"
        );
        assertEq(nftmarket.isListed(0), true);
        vm.stopPrank();
    }

    // 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
    function testBuyNFTFail() public {
        vm.startPrank(buyer);
        vm.expectRevert("price is zero");
        nftmarket.buyNFT(0);
        vm.stopPrank();
    }

    function testBuyNFTSuccess() public {
        vm.startPrank(owner);
        // 判断NFT
        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");
        // safeMint NFT
        mynft.safeMint(owner, "https://ipfs.io/ipfs/QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8");
        assertEq(mynft.balanceOf(owner), 2, "owner nft balance is not 2");
        assertEq(mynft.ownerOf(1), owner, "owner nft is not owner");

        // https://stackoverflow.com/questions/63252057/how-to-use-bytestouint-function-in-solidity-the-one-with-assembly
        // 上架
        mynft.safeTransferFrom(owner, address(nftmarket), 1, abi.encode(1e18));
        // "0x0000000000000000000000000000000000000000000000000001c6bf52634000"

        assertEq(nftmarket.isListed(1), true);
        // 给买家转账 10e18
        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);

        vm.stopPrank();

        vm.startPrank(buyer);

        // transferAndcall 购买NFT
        mytoken.transferAndcall(
            address(nftmarket),
            // 500000000000000,
            1e18,
            abi.encode(1)
        );

        // "0x0000000000000000000000000000000000000000000000000000000000000001"

        assertEq(mynft.ownerOf(1), buyer, "nft owner is not buyer");
        vm.stopPrank();
    }

    // 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzzListNFT(uint256 price) public {
        vm.assume(price > 0 && price <= 10000 * 1e18);
        vm.startPrank(owner);
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true);
        nftmarket.listNFT(0, price);
        assertEq(nftmarket.isListed(0), true);
        vm.stopPrank();
    }

    // function testFuzzRandomAddressBuyNFT(address newbuyer) public {
    function testFuzzRandomAddressBuyNFT() public {
        // 生成随机用户地址
        address newbuyer = vm.addr(uint256(keccak256(abi.encodePacked("randomUser", block.timestamp))));

        vm.assume(newbuyer != address(0) && newbuyer != owner);

        vm.startPrank(owner);
        // 查询NFT
        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");
        // 给 buyer 转账 10e18
        mytoken.transfer(newbuyer, 10e18);
        assertEq(mytoken.balanceOf(newbuyer), 10e18);
        // 授权并上架
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true, "owner nft is not approved for all");
        // NFT的拥有者才有权限上架
        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true, "nft market is not listed");
        vm.stopPrank();

        // 购买
        vm.startPrank(newbuyer);
        mytoken.approve(address(nftmarket), 1e18);
        assertEq(mytoken.allowance(newbuyer, address(nftmarket)), 1e18, "buyer token allowance is not 1e18");
        vm.expectEmit(true, true, true, true);
        emit Deal(owner, newbuyer, 0, 1e18);

        nftmarket.buyNFT(0);
        assertEq(mynft.ownerOf(0), newbuyer, "nft owner is not buyer");
        vm.stopPrank();
    }

    // 取消订单（上架后取消）：在 NFT 上架但未售出时，卖家可以取消订单，将 NFT 转回自己并删除订单信息
    function testcancelOrder() public {
        vm.startPrank(owner);
        // 授权并上架
        mynft.setApprovalForAll(address(nftmarket), true);

        // NFT的拥有者才有权限上架
        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true, "nft market is not listed");
        mytoken.transfer(buyer, 10e18);

        nftmarket.cancelOrder(0);
        assertEq(nftmarket.isListed(0), false, "nft market is not listed");
        vm.stopPrank();
    }

    // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariant_nftmarketTokenBalance() public view {
        assertEq(mytoken.balanceOf(address(nftmarket)), 0);
    }
}
