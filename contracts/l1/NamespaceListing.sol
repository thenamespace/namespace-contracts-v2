//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import {Controllable} from "../controllers/Controllable.sol";
import {INamespaceRegistry} from "./INamespaceRegistry.sol";
import {INameWrapperProxy} from "./INameWrapperProxy.sol";
import {INameWrapper, CANNOT_UNWRAP} from "../ens/INameWrapper.sol";
import {ListedENSName} from "./Types.sol";

error NotPermitted();
error NameNotListed(string nameLabel);

contract NamespaceLister is Controllable {
    event NameListed(string nameLabel, bytes32 node, address operator);
    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    INamespaceRegistry registry;
    INameWrapperProxy wrapperProxy;
    INameWrapper nameWrapper;

    constructor(
        address _nameWrapperProxy,
        address _nameWrapper,
        address _registry
    ) {
        nameWrapper = INameWrapper(_nameWrapper);
        registry = INamespaceRegistry(_registry);
        wrapperProxy = INameWrapperProxy(_nameWrapperProxy);
    }

    function list(
        string memory ensNameLabel,
        address paymentReceiver
    ) external {
        bytes32 nameNode = _namehash(ETH_NODE, ensNameLabel);

        require(_hasPermissions(msg.sender, nameNode), "Not permitted");

        wrapperProxy.setFuses(nameNode, uint16(CANNOT_UNWRAP));

        registry.set(
            nameNode,
            ListedENSName(ensNameLabel, nameNode, paymentReceiver, true)
        );

        emit NameListed(ensNameLabel, nameNode, msg.sender);
    }

    function unlist(string memory ensNameLabel) external {
        bytes32 nameNode = _namehash(ETH_NODE, ensNameLabel);

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

      function setNameWrapper(address _nameWrapper) external onlyOwner {
        nameWrapper = INameWrapper(_nameWrapper);
    }

    function _namehash(
        bytes32 parentNode,
        string memory nameLabel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parentNode, _labelhash(nameLabel)));
    }

    function _labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }
}
