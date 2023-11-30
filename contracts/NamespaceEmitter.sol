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
}
