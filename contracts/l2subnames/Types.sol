//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

struct MintL2SubnameContext {
    string subnameLabel;
    bytes32 parentNode;
    uint256 mintFee;
    address subnameOwner;
    address paymentReceiver;
    uint256 mintPrice;
    address resolver;
    uint64 expiry;
}