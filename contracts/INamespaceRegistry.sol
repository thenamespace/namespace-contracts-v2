//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Types.sol";

interface INamespaceRegistry {
    function listings(bytes32 nameNode) external returns (ListedENSName memory);
}
