//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import {Controllable} from "./controllers/Controllable.sol";
import {INamespaceRegistry} from "./INamespaceRegistry.sol";
import {INameWrapperProxy} from "./NameWrapperProxy.sol";
import {INameWrapper, CANNOT_UNWRAP} from "./ens/INameWrapper.sol";
import {ListedENSName} from "./Types.sol";

error NotPermitted();
error NameNotListed(string nameLabel);

contract NamespaceListing is Controllable {
    event NameListed(string nameLabel, bytes32 node, address operator);
    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    INamespaceRegistry registry;
    INameWrapperProxy wrapperProxy;
    INameWrapper nameWrapper;

    constructor(
        address _controller,
        address _nameWrapperProxy,
        address _nameWrapper,
        address _registry
    ) Controllable(msg.sender, _controller) {
        nameWrapper = INameWrapper(_nameWrapper);
        registry = INamespaceRegistry(_registry);
        wrapperProxy = INameWrapperProxy(_nameWrapperProxy);
    }

    modifier isNameOwner(bytes32 node) {
         address nameOwner = INameWrapper(nameWrapperAddress).ownerOf(
            uint256(node)
        );

        if (nameOwner != msg.sender && !_isApprovedForAll(nameOwner, msg.sender)) {
            revert NotNameOwner(msg.sender, nameOwner);
        }
        _;
    }

    function list(
        string memory ensNameLabel,
        bytes32 nameNode,
        address paymentReceiver
<<<<<<< HEAD
    ) external {
        require(_hasPermissions(msg.sender, nameNode), "Not permitted");

        wrapperProxy.setFuses(
            nameNode,
            uint16(CANNOT_UNWRAP)
        );
=======
    ) external isNameOwner(nameNode) {
>>>>>>> ddeb5a2 (test)

        registry.set(
            nameNode,
            ListedENSName(ensNameLabel, nameNode, paymentReceiver, true)
        );

        emit NameListed(ensNameLabel, nameNode, msg.sender);
    }

    function unlist(string memory ensNameLabel, bytes32 nameNode) external {
        require(_hasPermissions(msg.sender, nameNode), "Not permitted");
        if (!registry.get(nameNode).isListed) {
            revert NameNotListed(ensNameLabel);
        }

        registry.remove(nameNode);
        emit NameUnlisted(ensNameLabel, nameNode, msg.sender);
    }

    function _hasPermissions(
        address lister,
        bytes32 node
    ) internal view returns (bool) {
        address nameOwner = nameWrapper.ownerOf(uint256(node));

        if (nameOwner == address(0)) {
            return false;
        }
        return
            nameOwner == lister ||
            nameWrapper.isApprovedForAll(nameOwner, lister);
    }
}
