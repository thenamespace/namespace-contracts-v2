//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

struct MintSubnameContext {
    bytes32 parentNode;
    string subnameLabel;
    address resolver;
    address subnameOwner;
    uint32 fuses;
    uint256 mintPrice;
    uint256 mintFee;
    uint64 ttl;
}

struct ListedENSName {
    string label;
    bytes32 nameNode;
    address paymentReceiver;
    bool isListed;
}
