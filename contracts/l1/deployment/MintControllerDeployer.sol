//SPDX-License-Identifier: MIT
pragma solidity ~0.8.24;

import {MintController} from "../MintController.sol";

contract MintControllerDeployer {
    address public controller;

    constructor(
        address _owner,
        address _verifier,
        address _treasury,
        address _nameWrapperAddr,
        address _nameWrapperProxy,
        address _publicResolver
    ) {
        MintController _controller = new MintController(
            _verifier,
            _treasury,
            _nameWrapperAddr,
            _nameWrapperProxy,
            _publicResolver
        );
        _controller.transferOwnership(_owner);
        controller = address(_controller);
    }
}
