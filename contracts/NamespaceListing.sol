//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import "./controllers/Controllable.sol";
import "./INamespaceRegistry.sol";
import "./NameWrapperDelegate.sol";

error NotNameOwner(address current, address expected);
error NameNotListed(string nameLabel);

contract NamespaceListing is Controllable {
    event NameListed(string nameLabel, bytes32 node, address operator);
    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    address public nameWrapperDelegate;
    address public nameWrapper;
    INamespaceRegistry registry;

    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    constructor(
        address _controller,
        address _nameWrapperDelegate,
        address _nameWrapper,
        address _registry
    ) Controllable(_controller) {
        nameWrapperDelegate = _nameWrapperDelegate;
        nameWrapper = _nameWrapper;
        registry = INamespaceRegistry(_registry);
    }

    function list(
        string memory ensNameLabel,
        bytes32 nameNode,
        address paymentReceiver
    ) external {
        _isNameOwner(nameNode);

        // CANNOT_UNWRAP needs to be burned to allow minting unruggable subnames
        NameWrapperDelegate(nameWrapperDelegate).setFuses(
            nameNode,
            uint16(CANNOT_UNWRAP)
        );

        registry.set(
            nameNode,
            ListedENSName(ensNameLabel, nameNode, paymentReceiver, true)
        );
        emit NameListed(ensNameLabel, nameNode, msg.sender);
    }

    function unlist(string memory ensNameLabel) external {
        bytes32 nameNode = _node(ETH_NODE, ensNameLabel);

        _isNameOwner(nameNode);

        if (!registry.get(nameNode).isListed) {
            revert NameNotListed(ensNameLabel);
        }

        registry.remove(nameNode);
        emit NameUnlisted(ensNameLabel, nameNode, msg.sender);
    }

    function _isNameOwner(bytes32 node) internal view {
        address nameOwner = INameWrapper(nameWrapper).ownerOf(uint256(node));

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
