// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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

        // 6. 账户1 在 ERC721 合约上调用 setApprovalForAll 授权 NFTMarket 合约，参数为 NFTMarket 合约地址和 true
        mynft.setApprovalForAll(address(nftmarket), true);
        assertEq(mynft.isApprovedForAll(owner, address(nftmarket)), true);

        // 7. 账户1 在 NFTMarket 合约上调用 listNFT 挂单（上架 tokenId 为 0 的 NFT）
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");

        // 测试事件 NewOrder
        // event NewOrder(address seller, uint256 tokenId, uint256 price);
        vm.expectEmit(true, true, true, true);
        emit NewOrder(owner, 0, 1e18);

        nftmarket.listNFT(0, 1e18);
        assertEq(nftmarket.isListed(0), true);

        assertEq(nftmarket.getOrderLength(), 1);
        // 8. 账户1 在 ERC20 合约上调用 transfer 转移 10个 ERC20 token 给 账户2
        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);
        assertEq(mytoken.balanceOf(owner), 90e18);

        vm.stopPrank();

        // 购买
        vm.startPrank(buyer);
        // 9. 账户2 在 ERC20 合约上调用 approve 方法授权 NFTMarket 合约使用1个ERC20token，参数为 NFTMarket 合约地址 和数量 1,000,000,000,000,000,000
        mytoken.approve(address(nftmarket), 1e18);
        assertEq(mytoken.allowance(buyer, address(nftmarket)), 1e18, "buyer token allowance is not 1e18");
        // 10. 账户2 在 NFTMarket 合约上调用 buyNFT 购买 tokenId 为 0 的 NFT
        vm.expectEmit(true, true, true, true);
        emit Deal(owner, buyer, 0, 1e18);
        nftmarket.buyNFT(0);
        assertEq(mynft.ownerOf(0), buyer, "nft owner is not buyer");
        vm.stopPrank();
    }
    // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓

    function invariant_nftmarketTokenBalance() public view {
        assertEq(mynft.balanceOf(address(nftmarket)), 0);
    }
}
