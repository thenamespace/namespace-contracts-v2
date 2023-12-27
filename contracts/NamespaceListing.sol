//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import "./controllers/Controllable.sol";
import "./INamespaceRegistry.sol";
import "./NameWrapperDelegate.sol";

contract NamespaceListing is Controllable {
    error NotNameOwner(address current, address expected);
    error NameNotListed(string nameLabel);

    event NameListed(string nameLabel, bytes32 node, address operator);
    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    address public nameWrapperDelegate;
    INamespaceRegistry registry;

    constructor(
        address _controller,
        address _nameWrapperDelegate,
        address _registry
    ) Controllable(msg.sender, _controller) {
        nameWrapperDelegate = _nameWrapperDelegate;
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

    function unlist(string memory ensNameLabel, bytes32 nameNode) external {
        _isNameOwner(nameNode);

        if (!registry.get(nameNode).isListed) {
            revert NameNotListed(ensNameLabel);
        }

        registry.remove(nameNode);
        emit NameUnlisted(ensNameLabel, nameNode, msg.sender);
    }

    function _isNameOwner(bytes32 node) internal view {
        address nameOwner = NameWrapperDelegate(nameWrapperDelegate).ownerOf(uint256(node));

        if (nameOwner != msg.sender) {
            revert NotNameOwner(msg.sender, nameOwner);
        }
    }
}
