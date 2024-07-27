// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRegistryEmitter {
    function emitNodeTransfer(bytes32 node, bytes32 parentNode, address from, address to) external;

    function emitNodeBurned(bytes32 node, bytes32 parentNode, address executor) external;

    function emitNodeCreated(
        string memory label,
        bytes32 node,
        bytes32 parentNode,
        uint256 expiry
    ) external;

    function emitExpirySet(bytes32 node, uint256 expiry) external;

    function setApprovedEmitter(
        address emitter,
        bool value
    ) external;

    function emitDelegateChanged(
        address delegate,
        bool approved
    ) external;
}
