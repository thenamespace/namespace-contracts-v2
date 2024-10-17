// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Controllable} from "../../controllers/Controllable.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";

interface IRegistryControllerProxy {
    function register(
        address registry,
        string[] memory labels,
        address owner,
        uint256 expiry
    ) external returns (bytes32);
    function register(
        address registry,
        string memory label,
        address owner,
        uint256 expiration
    ) external returns (bytes32);
    function setExpiry(
        address registry,
        bytes32 node,
        uint256 expiration
    ) external;
}

contract RegistryControllerProxy is IRegistryControllerProxy, Controllable {
    function register(
        address registry,
        string[] memory labels,
        address owner,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        return IEnsNameRegistry(registry).register(labels, owner, expiry);
    }
    function register(
        address registry,
        string memory label,
        address owner,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        return IEnsNameRegistry(registry).register(label, owner, expiry);
    }
    function setExpiry(
        address registry,
        bytes32 node,
        uint256 expiration
    ) external onlyController {
        IEnsNameRegistry(registry).setExpiry(node, expiration);
    }
}
