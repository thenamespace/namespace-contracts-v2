// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Controllable} from "../../controllers/Controllable.sol";
import {INodeRegistryResolver} from "./INodeRegistryResolver.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";

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

    /**
     * @dev Sets the registry address for a given node.
     * @param node The subname node namehash -> namehash("subname.name.eth").
     * @param parentNode Nodehash of a parent registry node -> namehash("name.eth").
     * @return address Returns address of subnode owner, zero address is node is not owned
     * reverts if the registry is not present for parentNode
     */
    function subnodeOwner(
        bytes32 node,
        bytes32 parentNode
    ) external view returns (address) {
        address registryAddress = nodeRegistries[parentNode];

        require(registryAddress != address(0), "Registry not found");

        return IEnsNameRegistry(registryAddress).ownerOf(uint256(node));
    }
}
