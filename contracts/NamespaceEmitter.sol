//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./controllers/Controllable.sol";

contract NamespaceEmitter is Controllable {
    event SubnameMinted(
        bytes32 indexed parentNode,
        string label,
        uint256 price,
        address indexed paymentReceiver,
        address sender,
        address subnameOwner
    );

    event NameListed(
        string nameLabel,
        bytes32 node,
        address paymentReceiver,
        address operator
    );

    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    constructor(address _controller) Controllable(_controller) {}

    function emitSubnameMinted(
        string calldata label,
        bytes32 parentNode,
        uint price,
        address paymentReceiver,
        address minter,
        address subnameOwner
    ) external onlyController {
        emit SubnameMinted(
            parentNode,
            label,
            price,
            paymentReceiver,
            minter,
            subnameOwner
        );
    }

    function emitNameListed(
        string calldata nameLabel,
        bytes32 nameNode,
        address paymentReceiver,
        address operator
    ) external onlyController {
        emit NameListed(nameLabel, nameNode, paymentReceiver, operator);
    }

    function emitNameUnlisted(
        string calldata nameLabel,
        bytes32 nameNode,
        address operator
    ) external onlyController {
        emit NameUnlisted(nameLabel, nameNode, operator);
    }
}
