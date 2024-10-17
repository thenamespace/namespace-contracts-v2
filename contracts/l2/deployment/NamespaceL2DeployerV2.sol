// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NameRegistryController} from "../controller/NameRegistryController.sol";
import {RegistryControllerProxy} from "../controller/RegistryControllerProxy.sol";
import {TokenMetadata} from "../registries/TokenMetadata.sol";

contract NamespaceL2DeployerV2 {
    address public proxy;
    address public controller;
    address public tokenMetadata;

    constructor(
        address _verifier,
        address _treasury,
        string memory _baseUri,
        address _registryResolver,
        address _emitter,
        address _resolver,
        address _owner
    ) {
        RegistryControllerProxy _proxy = new RegistryControllerProxy();
        address proxyAddress = address(_proxy);
        proxy = proxyAddress;

        TokenMetadata _tokenMetadata = new TokenMetadata(_baseUri);
        tokenMetadata = address(_tokenMetadata);

        _tokenMetadata.transferOwnership(_owner);

        NameRegistryController _controller = new NameRegistryController(
            _verifier,
            _treasury,
            address(tokenMetadata),
            _registryResolver,
            _emitter,
            _resolver,
            proxyAddress
        );
        address controllerAddress = address(_controller);
        controller = controllerAddress;
        _proxy.setController(controllerAddress, true);
        _proxy.transferOwnership(_owner);

        _controller.transferOwnership(_owner);

        // emitter -> setController(controller,true);
        // registryResolver -> setController(controller, true);
        // go to every ERC721 deployed and -> setController(proxy, true);
    }
}
