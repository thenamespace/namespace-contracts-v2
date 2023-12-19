//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "../NamespaceRegistry.sol";
import "../NamespaceOperations.sol";

contract NamespaceDeployer {
    address public operations;
    address public registry;

    constructor(
        address _verifier,
        address _treasury,
        address _controller,
        address _nameWrapper
    ) {
        NamespaceRegistry _registry = new NamespaceRegistry(msg.sender);
        NamespaceOperations _operations = new NamespaceOperations(
            _verifier,
            _treasury,
            msg.sender,
            _nameWrapper,
            address(_registry)
        );


        registry = address(_registry);
        operations = address(_operations);

        _registry.setController(address(_operations), true);
        _registry.transferOwnership(_controller);
        _operations.transferOwnership(_controller);
    }
}
