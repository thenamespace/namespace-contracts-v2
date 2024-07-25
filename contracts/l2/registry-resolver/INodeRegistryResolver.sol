// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface INodeRegistryResolver {
    function setNodeRegistry(bytes32 node, address registry) external;
    function nodeRegistries(bytes32 node) external view returns(address);
}