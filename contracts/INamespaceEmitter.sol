//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

interface INamespaceEmitter {
    function emitSubnameMinted(
        string calldata label,
        bytes32 parentNode,
        uint price,
        address paymentReceiver,
        address minter,
        address subnameOwner
    ) external;

    function emitNameListed(
        string calldata nameLabel,
        bytes32 nameNode,
        address paymentReceiver,
        address operator
    ) external;

    function emitNameUnlisted(
        string calldata nameLabel,
        bytes32 nameNode,
        address operator
    ) external;
}
