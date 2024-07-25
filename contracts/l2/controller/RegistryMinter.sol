// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry, RegistryConfig} from "../registries/IEnsNameRegistry.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";

error RegistryNotFound(bytes32);
error InsufficientBalance(uint256, uint256);

abstract contract RegistryMinter {
    event NameMinted(
        string label,
        bytes32 parentNode,
        address owner,
        address resolver,
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
        address registryAddress = getRegistryResolver().nodeRegistries(
            context.parentNode
        );

        if (registryAddress == address(0)) {
            revert RegistryNotFound(context.parentNode);
        }

        if (resolverData.length > 0) {
            _mintWithData(context, registryAddress, resolverData);
        } else {
            _mintSimple(context, registryAddress);
        }

        _transferFees(context);

        emit NameMinted(
            context.label,
            context.parentNode,
            context.owner,
            context.resolver,
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
    ) internal {
        bytes32 node = IEnsNameRegistry(registryAddress).register(
            context.label,
            context.owner,
            context.resolver,
            context.expiry
        );
        getRegistryResolver().setNodeRegistry(node, registryAddress);
    }

    function _mintWithData(
        MintContext memory context,
        address registryAddress,
        bytes[] memory resolverData
    ) internal {
        bytes32 node = IEnsNameRegistry(registryAddress).register(
            context.label,
            address(this),
            context.resolver,
            context.expiry
        );

        getRegistryResolver().setNodeRegistry(node, registryAddress);
        setRecordsWithMulticall(context.resolver, resolverData);

        uint256 tokenId = uint256(node);
        IEnsNameRegistry(registryAddress).transferFrom(
            address(this),
            context.owner,
            tokenId
        );
    }

    function _transferFees(MintContext memory context) internal {
        uint256 totalPrice = context.fee + context.price;
        if (msg.value < totalPrice) {
            revert InsufficientBalance(totalPrice, msg.value);
        }

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

    function setRecordsWithMulticall(
        address resolver,
        bytes[] memory resolverData
    ) internal {
        IMulticallable(resolver).multicall(resolverData);
    }

    function getRegistryResolver()
        internal
        view
        virtual
        returns (INodeRegistryResolver);

    function getTreasury() internal view virtual returns (address);
}
