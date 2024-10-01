// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {MyERC20Token} from "../src/MyERC20Token.sol";
import {MyERC721Token} from "../src/MyERC721Token.sol";
import {SigUtils} from "../src/SigUtils.sol";

contract NFTMarketTest is Test {
    MyERC20Token public mytoken;
    MyERC721Token public mynft;
    NFTMarket public nftmarket;
    SigUtils internal sigUtils;
    SigUtils internal mytoken_sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal buyerPrivateKey;

    address internal owner;
    address internal buyer;

    uint256 public deadline = block.timestamp + 2 days;
    uint256 public tokenId = 0;
    uint256 internal price = 1e18;
    uint256 internal nonce = 0;

    event Deal(address seller, address buyer, uint256 tokenId, uint256 price);
    event NewOrder(address seller, uint256 tokenId, uint256 price);

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        buyerPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        buyer = vm.addr(buyerPrivateKey);
        // 1. 部署 ERC20 合约
        mytoken = new MyERC20Token(owner);
        // 2. 部署 ERC721 合约
        mynft = new MyERC721Token(owner);
        // 3. 使用 ERC20 合约地址 和 ERC721 合约地址作为初始化参数部署 NFTMarket 合约
        nftmarket = new NFTMarket(address(mytoken), address(mynft));

        mytoken_sigUtils = new SigUtils(mytoken.DOMAIN_SEPARATOR());
        sigUtils = new SigUtils(nftmarket.DOMAIN_SEPARATOR());

        vm.startPrank(owner); // 默认是测试合约
        // 4. 账户1 owner 在 ERC20 合约上 mint token
        vm.label(owner, "ERC20owner");
        mytoken.mint(owner, 100e18);
        // 5. 账户1 owner 在 ERC721 合约上 safeMint NFT
        mynft.safeMint(owner, "https://ipfs.io/ipfs/QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8");

        vm.stopPrank();
    }

    function test_PermitBuy() public {
        // 1. 上架
        _listNFTMarket();

        // 2. 购买
        vm.startPrank(buyer);

        // 3. ERC20 permit
        bytes memory permitSignature = _getEIP2612Signature();

        // 4. 白名单授权
        bytes memory whiteListSignature = _getWhiteListSignature();

        // 5. 上架签名
        bytes memory sellListingSignature = _getSellListingSignature();

        assertEq(mytoken.allowance(buyer, address(nftmarket)), 0);
        nftmarket.permitBuy(
            NFTMarket.LimitOrder(
                address(nftmarket),
                address(mynft),
                tokenId,
                address(mytoken),
                price,
                deadline,
                owner,
                sellListingSignature
            ),
            permitSignature,
            whiteListSignature
        );
        assertEq(mytoken.allowance(buyer, address(nftmarket)), 0);
        assertEq(mytoken.balanceOf(buyer), 9e18);

        assertEq(mynft.ownerOf(tokenId), buyer, "nft owner is not buyer");
        vm.stopPrank();
    }

    function _listNFTMarket() private {
        // 1. 上架
        vm.startPrank(owner);
        // 判断NFT
        assertEq(mynft.balanceOf(owner), 1, "owner nft balance is not 1");
        assertEq(mynft.ownerOf(0), owner, "owner nft is not owner");

        // https://stackoverflow.com/questions/63252057/how-to-use-bytestouint-function-in-solidity-the-one-with-assembly
        // 上架
        mynft.safeTransferFrom(owner, address(nftmarket), 0, abi.encode(1e18));
        assertEq(nftmarket.isListed(0), true);

        // 给买家转账 10e18
        mytoken.transfer(buyer, 10e18);
        assertEq(mytoken.balanceOf(buyer), 10e18);
        vm.stopPrank();
    }

    function _getEIP2612Signature() private view returns (bytes memory) {
        SigUtils.Permit memory permit =
            SigUtils.Permit({owner: buyer, spender: address(nftmarket), value: price, nonce: nonce, deadline: deadline});

        bytes32 digest = mytoken_sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        bytes memory permitSignature = abi.encodePacked(r, s, v);
        return permitSignature;
    }

    function _getWhiteListSignature() private view returns (bytes memory) {
        SigUtils.PermitBuy memory PermitBuy =
            SigUtils.PermitBuy({seller: owner, buyer: buyer, tokenId: tokenId, price: price, deadline: deadline});

        bytes32 digest_whitelist = sigUtils.getPermitBuyTypedDataHash(PermitBuy);

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ownerPrivateKey, digest_whitelist);
        bytes memory whitelistSignature = abi.encodePacked(r1, s1, v1);
        return whitelistSignature;
    }

    function _getSellListingSignature() private view returns (bytes memory) {
        SigUtils.PermitLimitOrder memory PermitLimitOrder = SigUtils.PermitLimitOrder({
            maker: address(nftmarket),
            nft: address(mynft),
            tokenId: tokenId,
            payToken: address(mytoken),
            price: price,
            deadline: deadline
        });

        bytes32 digest_list = sigUtils.getPermitLimitOrderTypedDataHash(PermitLimitOrder);

        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(ownerPrivateKey, digest_list);
        bytes memory sellListingSignature = abi.encodePacked(r2, s2, v2);
        return sellListingSignature;
    }
}
