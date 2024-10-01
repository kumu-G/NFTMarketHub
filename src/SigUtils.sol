// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract SigUtils {
    bytes32 internal DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 private constant _LIMIT_ORDER_TYPE_HASH = keccak256(
        "LimitOrder(address maker,address nft,uint256 tokenId,address payToken,uint256 price,uint256 deadline)"
    );

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    struct PermitBuy {
        address seller;
        address buyer;
        uint256 tokenId;
        uint256 price;
        uint256 deadline;
    }

    struct PermitLimitOrder {
        address maker;
        address nft;
        uint256 tokenId;
        address payToken;
        uint256 price;
        uint256 deadline;
    }

    // computes the hash of a permit
    function getStructHash(Permit memory _permit) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(PERMIT_TYPEHASH, _permit.owner, _permit.spender, _permit.value, _permit.nonce, _permit.deadline)
        );
    }

    function getPermitBuyStructHash(PermitBuy memory _PermitBuy) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("whitelist(address seller,address buyer,uint256 tokenId,uint256 price,uint256 deadline)"),
                _PermitBuy.seller,
                _PermitBuy.buyer,
                _PermitBuy.tokenId,
                _PermitBuy.price,
                _PermitBuy.deadline
            )
        );
    }

    function getPermitLimitOrderStructHash(PermitLimitOrder memory _PermitLimitOrder) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                _LIMIT_ORDER_TYPE_HASH,
                _PermitLimitOrder.maker,
                _PermitLimitOrder.nft,
                _PermitLimitOrder.tokenId,
                _PermitLimitOrder.payToken,
                _PermitLimitOrder.price,
                _PermitLimitOrder.deadline
            )
        );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getStructHash(_permit)));
    }

    function getPermitBuyTypedDataHash(PermitBuy memory _PermitBuy) public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getPermitBuyStructHash(_PermitBuy)));
    }

    function getPermitLimitOrderTypedDataHash(PermitLimitOrder memory _PermitLimitOrder)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getPermitLimitOrderStructHash(_PermitLimitOrder)));
    }
}
