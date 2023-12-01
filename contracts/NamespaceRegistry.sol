//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./controllers/Controllable.sol";
import "./ens/INameWrapper.sol";
import "./Types.sol";
import "./NamespaceEmitter.sol";

error NotNameOwner(address current, address expected);
error NameNotListed(string nameLabel);

contract NamespaceRegistry is Controllable {
    mapping(bytes32 => ListedENSName) listings;
    INameWrapper nameWrapper;
    NamespaceEmitter emitter;
    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    constructor(
        address _controller,
        INameWrapper _nameWrapper,
        NamespaceEmitter _emitter
    ) Controllable(_controller) {
        nameWrapper = _nameWrapper;
        emitter = _emitter;
    }

    function list(
        string memory ensNameLabel,
        address paymentReceiver
    ) external {
        bytes32 nameNode = _node(ETH_NODE, ensNameLabel);
        _isNameOwner(nameNode);

        listings[nameNode] = ListedENSName(
            ensNameLabel,
            nameNode,
            paymentReceiver,
            true
        );
        emitter.emitNameListed(
            ensNameLabel,
            nameNode,
            paymentReceiver,
            msg.sender
        );
    }

    function unlist(string memory ensNameLabel) external {
        bytes32 nameNode = _node(ETH_NODE, ensNameLabel);
        _isNameOwner(nameNode);

        if (!listings[nameNode].isListed) {
            revert NameNotListed(ensNameLabel);
        }

        delete listings[nameNode];
        emitter.emitNameUnlisted(ensNameLabel, nameNode, msg.sender);
    }

    function _isNameOwner(bytes32 node) internal view {
        address nameOwner = nameWrapper.ownerOf(uint256(node));

        if (nameOwner != msg.sender) {
            revert NotNameOwner(msg.sender, nameOwner);
        }
    }

    function _node(
        bytes32 parent,
        string memory label
    ) internal pure returns (bytes32) {
        bytes32 labelhash = keccak256(bytes(label));
        return keccak256(abi.encodePacked(parent, labelhash));
    }
}
