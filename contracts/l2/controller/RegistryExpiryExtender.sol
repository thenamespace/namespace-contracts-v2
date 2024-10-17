// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IRegistryControllerProxy} from "./RegistryControllerProxy.sol";
import {ControllerBase} from "./ControllerBase.sol";

abstract contract RegistryExpiryExtender is ControllerBase, ReentrancyGuard {
    event ExpiryExtended(bytes32 node, uint256 expiration);

    function _extendExpiry(
        ExtendExpiryContext memory context
    ) internal nonReentrant {
        address registrarAddress = registryResolver.nodeRegistries(
            context.node
        );

        require(registrarAddress != address(0), "Registrar not found");

        controllerProxy.setExpiry(
            registrarAddress,
            context.node,
            context.expiry
        );

        transferFunds(context.price, context.fee, context.paymentReceiver);

        emit ExpiryExtended(context.node, context.expiry);
    }
}
