// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AddrResolver} from "./profiles/AddrResolver.sol";
import {ContentHashResolver} from "./profiles/ContentHashResolver.sol";
import {TextResolver} from "./profiles/TextResolver.sol";
import {Multicallable} from "./Multicallable.sol";
import {InterfaceResolver} from "./profiles/InterfaceResolver.sol";
import {PubkeyResolver} from "./profiles/PubkeyResolver.sol";
import {NameResolver} from "./profiles/NameResolver.sol";
import {ABIResolver} from "./profiles/ABIResolver.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";
import {ExtendedResolver} from "./profiles/ExtendedResolver.sol";

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract NamePublicResolver is
    AddrResolver,
    ContentHashResolver,
    TextResolver,
    InterfaceResolver,
    PubkeyResolver,
    NameResolver,
    ABIResolver,
    ExtendedResolver,
    Multicallable
{
    INodeRegistryResolver public registryResolver;

    constructor(address _registryResolver) {
        registryResolver = INodeRegistryResolver(_registryResolver);
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        address registrarAddress = registryResolver.nodeRegistries(node);

        if (registrarAddress == address(0)) {
            return false;
        }

        uint256 tokenId = uint256(node);
        return
            msg.sender == IEnsNameRegistry(registrarAddress).ownerOf(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceID
    )
        public
        view
        virtual
        override(
            AddrResolver,
            ContentHashResolver,
            TextResolver,
            ABIResolver,
            InterfaceResolver,
            PubkeyResolver,
            NameResolver,
            Multicallable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}
