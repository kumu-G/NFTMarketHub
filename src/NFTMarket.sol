// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/mocks/EIP712Verifier.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract NFTMarket is ERC165, IERC721Receiver, IERC1363Receiver, EIP712Verifier {
    IERC20 public erc20;
    IERC721 public erc721;

    string private constant SIGNING_DOMAIN = "NFT-Market";
    string private constant SIGNATURE_VERSION = "1";
    bytes32 private constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );
    bytes32 private constant _WHITE_LIST_TYPE_HASH =
        keccak256("whitelist(address seller,address buyer,uint256 tokenId,uint256 price,uint256 deadline)");

    struct Order {
        address seller;
        uint256 tokenId;
        uint256 price;
    }

    struct LimitOrder {
        address maker;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
        address seller;
        bytes signature;
    }

    mapping(bytes32 => bool) public orderMatched;

    mapping(uint256 => Order) public orderOfId; // token id to order
    Order[] public orders;
    mapping(uint256 => uint256) public idToOrderIndex; // token id to index in orders

    event Deal(address seller, address buyer, uint256 tokenId, uint256 price);
    event NewOrder(address seller, uint256 tokenId, uint256 price);
    event PriceChanged(address seller, uint256 tokenId, uint256 previousPrice, uint256 price);
    event OrderCancelled(address seller, uint256 tokenId);

    constructor(address _erc20, address _erc721) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        require(_erc20 != address(0), "zero address");
        require(_erc721 != address(0), "zero address");
        erc20 = IERC20(_erc20);
        erc721 = IERC721(_erc721);
    }

    function buyNFT(uint256 _tokenId) external {
        address seller = orderOfId[_tokenId].seller;
        address buyer = msg.sender;
        uint256 price = orderOfId[_tokenId].price;

        require(seller != buyer, "seller and buyer are the same");
        require(price > 0, "price is zero");
        //  remove order
        removeOrder(_tokenId);

        require(erc20.transferFrom(buyer, seller, price), "transfer failed");
        erc721.safeTransferFrom(address(this), buyer, _tokenId);

        emit Deal(seller, buyer, _tokenId, price);
    }

    function _buyNFT(address buyer, uint256 _tokenId, uint256 value) internal {
        uint256 price = orderOfId[_tokenId].price;
        address seller = orderOfId[_tokenId].seller;
        require(seller != address(0), "NFT not listed");
        require(price > 0, "price is zero");
        require(seller != buyer, "seller and buyer are the same");
        require(value >= price, "Insufficient payment");

        // 如果支付金额超过价格，退回多余的代币
        if (value > price) {
            require(erc20.transfer(buyer, value - price), "transfer price failed");
        }

        // 转移 ERC20 代币
        require(erc20.transfer(seller, price), "Token transfer failed");

        // 转移 NFT
        erc721.safeTransferFrom(address(this), buyer, _tokenId);
        removeOrder(_tokenId);
        emit Deal(seller, buyer, _tokenId, price);
    }

    // 上架后取消订单
    function cancelOrder(uint256 _tokenId) external {
        address seller = orderOfId[_tokenId].seller;
        require(seller == msg.sender, "not the seller");
        // 将NFT转回卖家
        erc721.safeTransferFrom(address(this), seller, _tokenId);
        //  remove order
        removeOrder(_tokenId);
        emit OrderCancelled(seller, _tokenId);
    }

    function changePrice(uint256 _tokenId, uint256 _price) external {
        address seller = orderOfId[_tokenId].seller;
        require(seller == msg.sender, "not the seller");
        require(_price > 0, "price is zero");
        uint256 previousPrice = orderOfId[_tokenId].price;
        orderOfId[_tokenId].price = _price;

        Order storage order = orders[idToOrderIndex[_tokenId]];
        order.price = _price;
        emit PriceChanged(seller, _tokenId, previousPrice, _price);
    }

    function isListed(uint256 _tokenId) public view returns (bool) {
        return orderOfId[_tokenId].seller != address(0);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        returns (bytes4)
    {
        require(operator == from, " invalid operator");
        require(from != address(0), "zero address");
        require(msg.sender == address(erc721), "invalid sender");
        require(erc721.ownerOf(tokenId) == address(this), "not owned by this contract");

        uint256 price = toUint256(data, 0);
        // uint256 price = abi.decode(data, (uint256));

        require(price > 0, "price is zero");
        // 上架
        orders.push(Order(from, tokenId, price));
        orderOfId[tokenId] = Order(from, tokenId, price);
        idToOrderIndex[tokenId] = orders.length - 1;
        emit NewOrder(from, tokenId, price);

        return this.onERC721Received.selector;
    }

    function removeOrder(uint256 _tokenId) internal {
        // 把index 和 最后一个元素进行调换，然后把index pop出去
        uint256 index = idToOrderIndex[_tokenId];
        uint256 lastIndex = orders.length - 1;
        if (index != lastIndex) {
            Order storage lastOrder = orders[lastIndex];
            idToOrderIndex[lastOrder.tokenId] = index;
            orders[index] = lastOrder;
        }
        orders.pop();
        delete orderOfId[_tokenId];
        delete idToOrderIndex[_tokenId];
    }

    // https://stackoverflow.com/questions/63252057/how-to-use-bytestouint-function-in-solidity-the-one-with-assembly
    function toUint256(bytes memory _bytes, uint256 _start) public pure returns (uint256) {
        require(_start + 32 >= _start, "Market: toUint256_overflow");
        require(_bytes.length >= _start + 32, "Market: toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function getOrderLength() external view returns (uint256) {
        return orders.length;
    }

    function getAllNFTs() external view returns (Order[] memory) {
        return orders;
    }

    function getMyNFTs() external view returns (Order[] memory) {
        uint256 length = orders.length;
        Order[] memory _orders = new Order[](length);
        uint256 count = 0;
        for (uint256 i = 0; i < length; i++) {
            // _orders[i] = orders[i];
            _orders[count] = orders[i];
            count++;
        }
        return _orders;
    }

    function listNFT(uint256 _tokenId, uint256 _price) external {
        // 检查NFT是否属于调用者
        require(erc721.ownerOf(_tokenId) == msg.sender, "NFT is not owned by sender");
        // 检查 _price 是否大于 0。如果不是，则抛出错误信息 "price is zero" 并中止交易。
        require(_price > 0, "price is zero");
        // 检查 _tokenId 是否已被列出。如果已被列出，则抛出错误信息 "NFT already listed" 并中止交易。
        require(isListed(_tokenId) == false, "NFT already listed");

        // 将订单信息添加到 orders 数组中
        orders.push(Order(msg.sender, _tokenId, _price));
        // 将订单信息存储在 orderOfId 映射中，以 _tokenId 为键。
        orderOfId[_tokenId] = Order(msg.sender, _tokenId, _price);
        // 将订单索引存储在 idToOrderIndex 映射中，以 _tokenId 为键，值为订单在 orders 数组中的索引（orders.length - 1）。
        idToOrderIndex[_tokenId] = orders.length - 1;

        // 发送 NFT 给 market contract
        erc721.transferFrom(msg.sender, address(this), _tokenId);
        // 触发 NewOrder 事件
        emit NewOrder(msg.sender, _tokenId, _price);
    }

    function onTransferReceived(address, address from, uint256 value, bytes calldata data)
        external
        override
        returns (bytes4)
    {
        require(msg.sender == address(erc20), "Invalid token contract");

        // uint256 tokenId = abi.decode(data, (uint256));
        uint256 tokenId = toUint256(data, 0);
        _buyNFT(from, tokenId, value);

        return this.onTransferReceived.selector;
    }

    function permitBuy(LimitOrder memory order, bytes memory permit2612Signature, bytes calldata whitelistSignature)
        external
    {
        address seller = orderOfId[order.tokenId].seller;
        address buyer = msg.sender;
        uint256 price = orderOfId[order.tokenId].price;
        require(seller != buyer, "seller and buyer are the same");
        require(price > 0, "price is zero");

        require(block.timestamp <= order.deadline, "permitBuy expired");
        require(permit2612Signature.length == 65, "signature must be 65 bytes long");

        // 检查白单签名是否来自于项目方的签署
        // 执行 ERC20 的 permit 进行 授权
        // 执行 ERC20 的转账
        // 执行 NFT  的转账
        // 验证白名单签名，确保调用者是经过授权的白名单用户。
        verify(whitelistSignature, seller, seller, buyer, order.tokenId, price, order.deadline);

        _verifySellListingSignature(order);

        // https://github.com/TaylorDurden/hello_foundry/blob/master/src/app/NFTMarketPermit.sol
        bytes32 r;
        bytes32 s;
        uint8 v;
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        /// @solidity memory-safe-assembly
        assembly {
            r := mload(add(permit2612Signature, 0x20))
            s := mload(add(permit2612Signature, 0x40))
            v := byte(0, mload(add(permit2612Signature, 0x60)))
        }

        // 使用 IERC20Permit 的 permit 方法进行代币授权。
        IERC20Permit(address(erc20)).permit(buyer, address(this), price, order.deadline, v, r, s);

        // remove order
        removeOrder(order.tokenId);
        // 完成代币转账和 NFT 转移。
        require(erc20.transferFrom(buyer, seller, price), "transfer failed");
        erc721.safeTransferFrom(address(this), buyer, order.tokenId);

        emit Deal(seller, buyer, order.tokenId, price);
    }

    function verify(
        bytes memory signature,
        address signer,
        address seller,
        address _buyer,
        uint256 _tokenId,
        uint256 _price,
        uint256 _deadline
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("whitelist(address seller,address buyer,uint256 tokenId,uint256 price,uint256 deadline)"),
                    seller,
                    _buyer,
                    _tokenId,
                    _price,
                    _deadline
                )
            )
        );
        // 验证签名是否来自于指定的签署者。
        address recoveredSigner = ECDSA.recover(digest, signature);
        require(recoveredSigner == signer, "Invalid whitelist signature");
    }

    function DOMAIN_SEPARATOR() external view virtual returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _verifySellListingSignature(LimitOrder memory order) internal {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _LIMIT_ORDER_TYPE_HASH,
                    order.maker,
                    order.nft,
                    order.tokenId,
                    order.payToken,
                    order.price,
                    order.deadline
                )
            )
        );
        // Check if the order has already been matched
        require(orderMatched[digest] == false, "NFT already matched");
        orderMatched[digest] = true;
        // 验证签名是否来自于指定的签署者。
        address recoveredSigner = ECDSA.recover(digest, order.signature);
        require(recoveredSigner == order.seller, "Invalid verifySellListingSignature");
    }
}
