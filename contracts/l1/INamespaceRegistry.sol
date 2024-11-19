//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Types.sol";

interface INamespaceRegistry {
    function set(bytes32 node, ListedENSName calldata name) external;

    function get(bytes32 node) external view returns (ListedENSName memory);

    function remove(bytes32 node) external;
}
