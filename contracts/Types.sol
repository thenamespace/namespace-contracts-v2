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
<<<<<<< HEAD
}
=======
}
>>>>>>> a264043 (Test)
=======
}
>>>>>>> ddeb5a2 (test)
