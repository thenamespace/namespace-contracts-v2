// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry, RegistryConfig} from "../registries/IEnsNameRegistry.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";
import {EnsUtils} from "../utils/EnsUtils.sol";
import {EnsNameRegistry} from "../registries/EnsNameRegistry.sol";
import {IRegistryEmitter} from "../registries/IRegistryEmitter.sol";

error RegistryAlreadyExists(bytes32);

abstract contract RegistryFactory {
    event RegistryDeployed(
        string label,
        string TLD,
        bytes32 node,
        address registrarAddress,
        string tokenName,
        string tokenSymbol,
        address owner,
        ParentControlType parentControl,
        ExpirableType expirableType
    );

    function _deploy(FactoryContext memory context) internal {
        bytes32 tdlHash = EnsUtils.namehash(bytes32(0), context.TLD);
        bytes32 nameNode = EnsUtils.namehash(tdlHash, context.label);
        INodeRegistryResolver registryResolver = getRegistryResolver();

        if (registryResolver.nodeRegistries(nameNode) != address(0)) {
            revert RegistryAlreadyExists(nameNode);
        }

        RegistryConfig memory config = RegistryConfig(
            context.parentControl,
            context.expirableType,
            context.tokenName,
            context.tokenSymbol,
            getRegistryURI(),
            context.owner,
            nameNode,
            address(getEmitter())
        );

        EnsNameRegistry registry = new EnsNameRegistry(config);

        getEmitter().setApprovedEmitter(address(registry), true);

        registry.setController(address(this), true);
        registry.transferOwnership(_owner());

        registryResolver.setNodeRegistry(nameNode, address(registry));

        emit RegistryDeployed(
            context.label,
            context.TLD,
            nameNode,
            address(address(registry)),
            context.tokenName,
            context.tokenSymbol,
            context.owner,
            context.parentControl,
            context.expirableType
        );
    }

    function getRegistryResolver() internal view virtual returns (INodeRegistryResolver);

    function getEmitter() internal view virtual returns (IRegistryEmitter);

    function getRegistryURI()
        internal
        view
        virtual
        returns (string memory);

    function _owner() internal view virtual returns(address);
}
