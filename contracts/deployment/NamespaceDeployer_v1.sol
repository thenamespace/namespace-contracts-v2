//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import {NamespaceRegistry} from "../NamespaceRegistry.sol";
import {NamespaceMinting} from "../NamespaceMinting.sol";
import {NamespaceListing} from "../NamespaceListing.sol";
import {NameWrapperProxy, INameWrapperProxy} from "../NameWrapperProxy.sol";
import {INamespaceRegistry} from "../INamespaceRegistry.sol";
<<<<<<< HEAD
import {INameWrapper} from "../ens/INameWrapper.sol";
=======
>>>>>>> ddeb5a2 (test)

contract NamespaceDeployer {
    address public registry;
    address public minting;
    address public listing;
    address public nameWrapperDelegate;
    address public test;

    constructor(
        address _verifier,
        address _treasury,
        address _owner,
        address _nameWrapper,
        address _reverseRegistrar,
        string memory minterVersion
    ) {
        NamespaceRegistry namespaceRegistry = new NamespaceRegistry(_owner);
        address namespaceRegistryAddr = address(namespaceRegistry);
        
<<<<<<< HEAD
        
        NameWrapperProxy wrapperProxy = new NameWrapperProxy(_nameWrapper);
=======
        NameWrapperProxy wrapperProxy = new NameWrapperProxy(_nameWrapper, namespaceRegistryAddr);
>>>>>>> ddeb5a2 (test)
        address wrapperProxyAddress = address(wrapperProxy);
        
        NamespaceListing lister = new NamespaceListing(
            _owner,
            wrapperProxyAddress,
            _nameWrapper,
            namespaceRegistryAddr
        );
        address listerAddress = address(lister);
<<<<<<< HEAD
    
=======
>>>>>>> ddeb5a2 (test)
        
        NamespaceMinting minter = new NamespaceMinting(
            _treasury,
            _owner,
            wrapperProxyAddress,
            _nameWrapper,
            namespaceRegistryAddr,
            _reverseRegistrar,
            _verifier,
            minterVersion
        );
        address minterAddress = address(minter);

        // lister should be able to set listed name records
        namespaceRegistry.setController(listerAddress, true);
        namespaceRegistry.transferOwnership(_owner);

        // minter and lister should be able to call methods of wrapper proxy
        wrapperProxy.setController(listerAddress, true);
        wrapperProxy.setController(minterAddress, true);
        wrapperProxy.setController(address(this), false);
        wrapperProxy.transferOwnership(_owner);

        lister.transferOwnership(_owner);
        minter.transferOwnership(_owner);

        nameWrapperDelegate = wrapperProxyAddress;
        listing = listerAddress;
        minting = minterAddress;
    }
}
