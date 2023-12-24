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
        // listing contract
        NamespaceListing _listing = new NamespaceListing(
            _controller,
            nameWrapperDelegate,
            _nameWrapper,
            registry
        );
        listing = address(_listing);

        // registry
        NamespaceRegistry _registry = new NamespaceRegistry(address(_listing));
        registry = address(_registry);

        // minting contract
        NamespaceMinting _minting = new NamespaceMinting(
            _treasury,
            _controller,
            _nameWrapper,
            address(_registry)
        );
        minting = address(_minting);

        // name wrapper delegate
        NameWrapperDelegate _nameWrapperDelegate = new NameWrapperDelegate(
            INameWrapper(_nameWrapper),
            _controller,
            _verifier
        );
        nameWrapperDelegate = address(_nameWrapperDelegate);
        _nameWrapperDelegate.setController(minting, true);

        // ownership transfer
        _registry.transferOwnership(_controller);
        _minting.transferOwnership(_controller);
        _listing.transferOwnership(_controller);
        _nameWrapperDelegate.transferOwnership(_controller);
    }
}
