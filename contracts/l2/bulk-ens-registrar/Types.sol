// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct RegistrationContext {
    string name;
    address owner;
    uint256 duration;
    bytes32 secret;
    address resolver;
    bytes[] data;
    bool reverseRecord;
    uint16 ownerControlledFuses;
    uint256 registrationPrice;
}

struct BulkRegistrationPrice {
    uint256[] prices;
    uint256 total;
}

struct BulkPriceContext {
    string label;
    uint256 duration;
}