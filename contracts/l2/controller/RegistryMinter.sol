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
        address registryAddress = getRegistryResolver().nodeRegistries(
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

        _transferFees(context);

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
        bytes32 node = IEnsNameRegistry(registryAddress).register(
            context.label,
            context.owner,
            context.expiry
        );
        getRegistryResolver().setNodeRegistry(node, registryAddress);
        return node;
    }

    function _mintWithData(
        MintContext memory context,
        address registryAddress,
        bytes[] memory resolverData
    ) internal returns (bytes32) {
        bytes32 node = IEnsNameRegistry(registryAddress).register(
            context.label,
            address(this),
            context.expiry
        );

        getRegistryResolver().setNodeRegistry(node, registryAddress);
        setRecordsWithMulticall(resolverData);

        uint256 tokenId = uint256(node);
        IEnsNameRegistry(registryAddress).transferFrom(
            address(this),
            context.owner,
            tokenId
        );
        return node;
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
        bytes[] memory resolverData
    ) internal {
        IMulticallable(getResolver()).multicall(resolverData);
    }

    function getRegistryResolver()
        internal
        view
        virtual
        returns (INodeRegistryResolver);

    function getTreasury() internal view virtual returns (address);

    function getResolver() internal view virtual returns (address);
}
