// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NamePublicResolver} from "../resolver/NamePublicResolver.sol";
import {NameRegistryController} from "../controller/NameRegistryController.sol";
import {RegistryEmitter} from "../registries/RegistryEmitter.sol";
import {NodeRegistryResolver} from "../registry-resolver/NodeRegistryResolver.sol";

contract NamespaceL2Deployer {
    address public resolver;
    address public controller;
    address public emitter;
    address public registryResolver;

    constructor(
        address _verifier,
        address _treasury,
        address _owner,
        string memory baseUri
    ) {
        NodeRegistryResolver _registryResolver = new NodeRegistryResolver();
        RegistryEmitter _emitter = new RegistryEmitter();
        NamePublicResolver _resolver = new NamePublicResolver(
            address(_registryResolver)
        );
        
        NameRegistryController _controller = new NameRegistryController(
            _verifier,
            _treasury,
            baseUri,
            address(_registryResolver),
            address(_emitter),
            address(_resolver)
        );

        _emitter.setController(address(_controller), true);
        _registryResolver.setController(address(_controller), true);

        _registryResolver.transferOwnership(_owner);
        _emitter.transferOwnership(_owner);
        _controller.transferOwnership(_owner);

        resolver = address(_resolver);
        controller = address(_controller);
        registryResolver = address(_registryResolver);
        emitter = address(_emitter);
    }
}
