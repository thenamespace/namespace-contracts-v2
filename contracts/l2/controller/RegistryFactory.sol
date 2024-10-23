// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry, RegistryConfig} from "../registries/IEnsNameRegistry.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";
import {EnsUtils} from "../utils/EnsUtils.sol";
import {EnsNameRegistry} from "../registries/EnsNameRegistry.sol";
import {IRegistryEmitter} from "../registries/IRegistryEmitter.sol";
import {IRegistryControllerProxy} from "./RegistryControllerProxy.sol";
import {ControllerBase} from "./ControllerBase.sol";

error RegistryAlreadyExists(bytes32);

abstract contract RegistryFactory is ControllerBase {
    event RegistryDeployed(
        string label,
        string TLD,
        bytes32 indexed node,
        address registryAddress,
        string tokenName,
        string tokenSymbol,
        address owner,
        ParentControlType parentControl,
        ExpirableType expirableType
    );

    function _deploy(
        FactoryContext memory context,
        bytes[] memory resolverData
    ) internal {
        bytes32 tdlHash = EnsUtils.namehash(bytes32(0), context.TLD);
        bytes32 nameNode = EnsUtils.namehash(tdlHash, context.label);

        if (registryResolver.nodeRegistries(nameNode) != address(0)) {
            revert RegistryAlreadyExists(nameNode);
        }

        EnsNameRegistry registry;
        if (resolverData.length > 0) {
            registry = _deployWithResolverData(nameNode, context, resolverData);
        } else {
            registry = _deploySimple(nameNode, context);
        }

        address registryAddress = address(registry);

        registry.setController(address(controllerProxy), true);
        registry.transferOwnership(owner());

        emit RegistryDeployed(
            context.label,
            context.TLD,
            nameNode,
            registryAddress,
            context.tokenName,
            context.tokenSymbol,
            context.owner,
            context.parentControl,
            context.expirableType
        );
    }

    function _deployWithResolverData(
        bytes32 nameNode,
        FactoryContext memory context,
        bytes[] memory resolverData
    ) internal returns (EnsNameRegistry) {
        RegistryConfig memory config = RegistryConfig(
            context.parentControl,
            context.expirableType,
            context.tokenName,
            context.tokenSymbol,
            tokenMetadata,
            address(this),
            nameNode,
            address(emitter)
        );
        EnsNameRegistry registry = new EnsNameRegistry(config);
        registryResolver.setNodeRegistry(nameNode, address(registry));
        emitter.setApprovedEmitter(address(registry), true);
        
        super.setResolverData(resolverData);

        registry.transferFrom(address(this), context.owner, uint256(nameNode));
        return registry;
    }

    function _deploySimple(
        bytes32 nameNode,
        FactoryContext memory context
    ) internal returns (EnsNameRegistry) {
        RegistryConfig memory config = RegistryConfig(
            context.parentControl,
            context.expirableType,
            context.tokenName,
            context.tokenSymbol,
            tokenMetadata,
            context.owner,
            nameNode,
            address(emitter)
        );
        EnsNameRegistry registry = new EnsNameRegistry(config);
        registryResolver.setNodeRegistry(nameNode, address(registry));
        emitter.setApprovedEmitter(address(registry), true);

        return registry;
    }

    function _setPermissions(bytes32 nameNode, address registryAddress) internal {
        registryResolver.setNodeRegistry(nameNode, registryAddress);
        emitter.setApprovedEmitter(registryAddress, true);
    }
}
