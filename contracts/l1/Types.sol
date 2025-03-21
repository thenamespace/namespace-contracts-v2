// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

bytes32 constant MINT_CONTEXT = keccak256(
    "MintContext(string label,bytes32 parentNode,address owner,uint256 price,uint256 fee,address paymentReceiver,uint256 expiry,uint256 signatureExpiry,address verifiedMinter,uint32 fuses)"
);

struct MintContext {
    address owner;
    string label;
    bytes32 parentNode;
    uint256 price;
    uint256 fee;
    address paymentReceiver;
    uint64 expiry;
    uint256 signatureExpiry;
    address verifiedMinter;
    uint32 fuses;
}