//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import {NamespaceRegistry} from "../NamespaceRegistry.sol";
import {NamespaceMinter} from "../NamespaceMinting.sol";
import {NamespaceLister} from "../NamespaceListing.sol";
import {NameWrapperProxy, INameWrapperProxy} from "../NameWrapperProxy.sol";
import {INamespaceRegistry} from "../INamespaceRegistry.sol";
import {INameWrapper} from "../../ens/INameWrapper.sol";

contract NamespaceDeployer {
    address public registry;
    address public minting;
    address public listing;
    address public proxy;

    constructor(
        address _verifier,
        address _treasury,
        address _owner,
        address _nameWrapperAddr,
        string memory minterVersion
    ) {
        NamespaceRegistry namespaceRegistry = new NamespaceRegistry();
        address namespaceRegistryAddr = address(namespaceRegistry);

        NameWrapperProxy wrapperProxy = new NameWrapperProxy(_nameWrapperAddr);
        address wrapperProxyAddress = address(wrapperProxy);

        NamespaceLister lister = new NamespaceLister(
            wrapperProxyAddress,
            _nameWrapperAddr,
            namespaceRegistryAddr
        );
        address listerAddress = address(lister);

        NamespaceMinter minter = new NamespaceMinter(
            _treasury,
            _verifier,
            wrapperProxyAddress,
            _nameWrapperAddr,
            namespaceRegistryAddr,
            minterVersion
        );

        address minterAddress = address(minter);

        // lister should be able to set listed name records
        namespaceRegistry.setController(listerAddress, true);
        namespaceRegistry.transferOwnership(_owner);

        // minter and lister should be able to call methods of wrapper proxy
        wrapperProxy.setController(listerAddress, true);
        wrapperProxy.setController(minterAddress, true);
        wrapperProxy.transferOwnership(_owner);

        lister.transferOwnership(_owner);
        minter.transferOwnership(_owner);

        proxy = wrapperProxyAddress;
        listing = listerAddress;
        minting = minterAddress;
        registry = namespaceRegistryAddr;
    }
}
