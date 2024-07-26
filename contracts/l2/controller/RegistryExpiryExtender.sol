// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract RegistryExpiryExtender is ReentrancyGuard {
    event ExpiryExtended(bytes32 node, uint256 expiration);

    function _extendExpiry(
        ExtendExpiryContext memory context
    ) internal nonReentrant {
        address registrarAddress = getRegistryResolver().nodeRegistries(
            context.node
        );

        require(registrarAddress != address(0), "Registrar not found");

        IEnsNameRegistry registrar = IEnsNameRegistry(registrarAddress);

        registrar.setExpiry(context.node, context.expiry);

        _transferFunds(context);

        emit ExpiryExtended(context.node, context.expiry);
    }

    function _transferFunds(ExtendExpiryContext memory context) internal {
        uint256 totalPrice = context.fee + context.price;
        require(msg.value >= totalPrice, "Insufficient balance");

        if (context.price > 0) {
            (bool sentToOwner, ) = payable(context.paymentReceiver).call{
                value: context.price
            }("");
            require(sentToOwner, "Could not transfer ETH to payment receiver");
        }

        if (context.fee > 0) {
            (bool sentToTreasury, ) = payable(getTreasury()).call{
                value: context.fee
            }("");
            require(sentToTreasury, "Could not transfer ETH to treasury");
        }

        uint256 remainder = msg.value - totalPrice;
        if (remainder > 0) {
            (bool sentToTreasury, ) = payable(msg.sender).call{
                value: remainder
            }("");
            require(sentToTreasury, "Could not transfer ETH to msg.sender");
        }
    }

    function getRegistryResolver()
        internal
        view
        virtual
        returns (INodeRegistryResolver);

    function getTreasury() internal view virtual returns (address);
}
