//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Types.sol";

interface INamespaceRegistry {
    function getListing(
        bytes32 node
    ) external view returns (ListedENSName memory);
}
