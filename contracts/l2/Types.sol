// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant MINT_CONTEXT = keccak256(
    "MintContext(string label,bytes32 parentNode,address owner,uint256 price,uint256 fee,address paymentReceiver,uint256 expiry,uint256 nonce)"
);

struct MintContext {
    address owner;
    string label;
    bytes32 parentNode;
    uint256 price;
    uint256 fee;
    address paymentReceiver;
    uint256 expiry;
    uint256 nonce;
}

bytes32 constant FACTORY_CONTEXT = keccak256(
    "FactoryContext(string tokenName,string tokenSymbol,string label,string TLD,address owner,uint8 parentControl,uint8 expirableType)"
);

struct FactoryContext {
    ParentControlType parentControl;
    ExpirableType expirableType;
    string tokenName;
    string tokenSymbol;
    string label;
    string TLD;
    address owner;
}

struct ExtendExpiryContext {
    bytes32 node;
    uint256 expiry;
    uint256 price;
    uint256 fee;
    address paymentReceiver;
    uint256 nonce;
}

bytes32 constant EXTEND_EXPIRY_CONTEXT = keccak256(
    "ExtendExpiryContext(bytes32 node,uint256 expiry,uint256 price,uint256 fee,address paymentReceiver,uint256 nonce)"
);

enum ExpirableType {
    NonExpirable,
    Expirable
}

enum ParentControlType {
    NonControllable,
    Controllable
}
