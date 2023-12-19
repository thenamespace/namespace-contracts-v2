//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./controllers/Controllable.sol";
import "./Types.sol";

error NotNameOwner(address current, address expected);
error NameNotListed(string nameLabel);

contract NamespaceRegistry is Controllable {
    mapping(bytes32 => ListedENSName) listings;

    constructor(address _controller) Controllable(_controller) {}

    function set(
        bytes32 node,
        ListedENSName calldata name
    ) external onlyController {
        listings[node] = name;
    }

    function get(bytes32 node) external view returns (ListedENSName memory) {
        return listings[node];
    }

    function remove(bytes32 node) external onlyController {
        delete listings[node];
    }
}
