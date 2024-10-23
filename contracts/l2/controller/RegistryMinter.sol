// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry, RegistryConfig} from "../registries/IEnsNameRegistry.sol";
import {IRegistryControllerProxy} from "./RegistryControllerProxy.sol";
import {ControllerBase} from "./ControllerBase.sol";

error RegistryNotFound(bytes32);
error InsufficientBalance(uint256, uint256);

abstract contract RegistryMinter is ControllerBase {

    event NameMinted(
        string label,
        bytes32 parentNode,
        bytes32 node,
        address owner,
        uint256 price,
        uint256 fee,
        address paymentReceiver,
        uint256 expiry,
        bytes extraData
    );

    function _mint(
        MintContext memory context,
        bytes[] memory resolverData,
        bytes calldata extraData
    ) internal {
        address registryAddress = registryResolver.nodeRegistries(
            context.parentNode
        );

        if (registryAddress == address(0)) {
            revert RegistryNotFound(context.parentNode);
        }

        bytes32 node;
        if (resolverData.length > 0) {
            node = _mintWithData(context, registryAddress, resolverData);
        } else {
            node = _mintSimple(context, registryAddress);
        }

        transferFunds(context.price, context.fee, context.paymentReceiver);

        emit NameMinted(
            context.label,
            context.parentNode,
            node,
            context.owner,
            context.price,
            context.fee,
            context.paymentReceiver,
            context.expiry,
            extraData
        );
    }

    function _mintSimple(
        MintContext memory context,
        address registryAddress
    ) internal returns (bytes32) {
        bytes32 node = controllerProxy.register(
            registryAddress,
            context.label,
            context.owner,
            context.expiry
        );
        registryResolver.setNodeRegistry(node, registryAddress);
        return node;
    }

    function _mintWithData(
        MintContext memory context,
        address registryAddress,
        bytes[] memory resolverData
    ) internal returns (bytes32) {
        bytes32 node = controllerProxy.register(
            registryAddress,
            context.label,
            address(this),
            context.expiry
        );

        registryResolver.setNodeRegistry(node, registryAddress);
        super.setResolverData(resolverData);

        uint256 tokenId = uint256(node);
        IEnsNameRegistry(registryAddress).transferFrom(
            address(this),
            context.owner,
            tokenId
        );
        return node;
    }
}
