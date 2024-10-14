// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant MINT_CONTEXT = keccak256(
    "MintContext(string label,bytes32 parentNode,address owner,uint256 price,uint256 fee,address paymentReceiver,uint256 expiry,uint256 signatureExpiry,address verifiedMinter)"
);

struct MintContext {
    address owner;
    string label;
    bytes32 parentNode;
    uint256 price;
    uint256 fee;
    address paymentReceiver;
    uint256 expiry;
    uint256 signatureExpiry;
    address verifiedMinter;
}

bytes32 constant FACTORY_CONTEXT = keccak256(
    "FactoryContext(string tokenName,string tokenSymbol,string label,string TLD,address owner,uint8 parentControl,uint8 expirableType,uint256 signatureExpiry)"
);

struct FactoryContext {
    ParentControlType parentControl;
    ExpirableType expirableType;
    string tokenName;
    string tokenSymbol;
    string label;
    string TLD;
    address owner;
    uint256 signatureExpiry;
}

struct ExtendExpiryContext {
    bytes32 node;
    uint256 expiry;
    uint256 price;
    uint256 fee;
    address paymentReceiver;
    uint256 signatureExpiry;
}

bytes32 constant EXTEND_EXPIRY_CONTEXT = keccak256(
    "ExtendExpiryContext(bytes32 node,uint256 expiry,uint256 price,uint256 fee,address paymentReceiver,uint256 signatureExpiry)"
);

enum ExpirableType {
    NonExpirable,
    Expirable
}

enum ParentControlType {
    NonControllable,
    Controllable
}
