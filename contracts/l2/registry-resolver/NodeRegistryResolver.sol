// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Controllable} from "../../controllers/Controllable.sol";
import {INodeRegistryResolver} from "./INodeRegistryResolver.sol";

/**
 * @title NodeRegistryResolver
 * @dev This contract stores registry addresses for a given node,
 * allowing registry discovery.
 */
contract NodeRegistryResolver is INodeRegistryResolver, Controllable {
    mapping(bytes32 => address) public nodeRegistries;

    event NodeSet(bytes32 node, address registrar);

    /**
     * @dev Sets the registry address for a given node.
     * Can only be called by a controller.
     * @param node The node identifier -> namehash("name.eth").
     * @param registrar The address of the registrar for the node.
     */
    function setNodeRegistry(
        bytes32 node,
        address registrar
    ) external onlyController {
        if (nodeRegistries[node] == address(0)) {
            nodeRegistries[node] = registrar;
            emit NodeSet(node, registrar);
        }
    }
}
