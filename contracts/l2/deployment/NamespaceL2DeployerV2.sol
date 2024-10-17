// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {NameRegistryController} from "../controller/NameRegistryController.sol";
import {RegistryControllerProxy} from "../controller/RegistryControllerProxy.sol";
import {TokenMetadata} from "../registries/TokenMetadata.sol";

contract NamespaceL2DeployerV2 {
    address public controller;

    constructor(
        address _verifier,
        address _treasury,
        address _registryResolver,
        address _emitter,
        address _resolver,
        address _owner,
        address _proxyAddress,
        address _tokenMetadata
    ) {

        NameRegistryController _controller = new NameRegistryController(
            _verifier,
            _treasury,
            _tokenMetadata,
            _registryResolver,
            _emitter,
            _resolver,
           _proxyAddress
        );
    
        _controller.transferOwnership(_owner);

        // emitter -> setController(controller,true);
        // registryResolver -> setController(controller, true);
        // go to every ERC721 deployed and -> setController(proxy, true);
    }
}
