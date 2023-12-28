//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "../NamespaceRegistry.sol";
import "../NamespaceMinting.sol";
import "../NamespaceListing.sol";
import "../NameWrapperDelegate.sol";

contract NamespaceDeployer {
    address public registry;
    address public minting;
    address public listing;
    address public nameWrapperDelegate;

    constructor(
        address _verifier,
        address _treasury,
        address _controller,
        address _nameWrapper
    ) {
        // name wrapper delegate
        NameWrapperDelegate _nameWrapperDelegate = new NameWrapperDelegate(
            INameWrapper(_nameWrapper),
            _controller,
            _verifier
        );
        address nameWrapperDelegateAddress = address(_nameWrapperDelegate);

        // registry
        NamespaceRegistry _registry = new NamespaceRegistry(_controller);
        address registryAddress = address(_registry);
        
        // listing contract
        NamespaceListing _listing = new NamespaceListing(
            _controller,
            nameWrapperDelegateAddress,
            registryAddress
        );
        address listingAddress = address(_listing);


        // minting contract
        NamespaceMinting _minting = new NamespaceMinting(
            _treasury,
            _controller,
            nameWrapperDelegateAddress,
            registryAddress
        );
        address mintingAddress = address(_minting);

        _nameWrapperDelegate.setController(listingAddress, true);
        _nameWrapperDelegate.setController(mintingAddress, true);
        _registry.setController(listingAddress, true);

        // ownership transfer
        _registry.transferOwnership(_controller);
        _minting.transferOwnership(_controller);
        _listing.transferOwnership(_controller);
        _nameWrapperDelegate.transferOwnership(_controller);

        registry = registryAddress;
        minting = mintingAddress;
        listing = listingAddress;
        nameWrapperDelegate = nameWrapperDelegateAddress;
    }
}
