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
    uint64 expiry;
}

struct MintParameters {
    bytes data;
    bytes signature;
    bytes[] records;
}


struct ListedENSName {
    string label;
    bytes32 nameNode;
    address paymentReceiver;
    bool isListed;
}

struct ReverseRecord {
    bool set;
    string fullName;
<<<<<<< HEAD
}
=======
}
>>>>>>> a264043 (Test)
