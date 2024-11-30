// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@ensdomains/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ABIResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/AddrResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/ContentHashResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/NameResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/TextResolver.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol";
import "@ensdomains/ens-contracts/contracts/resolvers/profiles/InterfaceResolver.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {INameWrapper} from "@ensdomains/ens-contracts/contracts/wrapper/INameWrapper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract EnsResolverBase is
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    InterfaceResolver,
    NameResolver,
    TextResolver,
    Ownable
{
    ENS immutable ens;
    INameWrapper immutable nameWrapper;

    constructor(address _ENS, address _nameWrapper) {
        ens = ENS(_ENS);
        nameWrapper = INameWrapper(_nameWrapper);
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        return hasNamePermissions(node);
    }

    function hasNamePermissions(bytes32 node) internal view returns (bool) {
        return
            ens.owner(node) == _msgSender() ||
            nameWrapper.canModifyName(node, _msgSender());
    }

    modifier isNodeOwner(bytes32 node) {
        require(hasNamePermissions(node), "No permissions to modify name");
        _;
    }

    function resolve(
        bytes memory dnsName,
        bytes memory data
    ) public view virtual returns (bytes memory);

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            Multicallable,
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            InterfaceResolver,
            NameResolver,
            TextResolver
        )
        returns (bool)
    {
        return
            interfaceId == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
