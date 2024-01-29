//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import {INameWrapper} from "./ens/INameWrapper.sol";
import {Controllable} from "./controllers/Controllable.sol";
import {INamespaceRegistry} from "./NamespaceRegistry.sol";

interface INameWrapperProxy {
    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external returns (bytes32);

    function setFuses(
        bytes32 node,
        uint16 ownerControlledFuses
    ) external returns (uint32 newFuses);
}

contract NameWrapperProxy is Controllable, INameWrapperProxy {
    INameWrapper nameWrapper;

    constructor(
        address _nameWrapperAddress
    ) Controllable(msg.sender, msg.sender) {
        nameWrapper = INameWrapper(_nameWrapperAddress);
    }

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external onlyController returns (bytes32) {

        bytes32 subnameNode = keccak256(abi.encode(label, node));
        require(
            nameWrapper.ownerOf(uint256(subnameNode)) == address(0),
            "Subname is not available"
        );
        return
            nameWrapper.setSubnodeRecord(
                node,
                label,
                owner,
                resolver,
                ttl,
                fuses,
                expiry
            );
    }

    function setFuses(
        bytes32 node,
        uint16 ownerControlledFuses
    ) external onlyController returns (uint32 newFuses) {
        return
            nameWrapper.setFuses(
                node,
                ownerControlledFuses
            );
    }

    function setNameWrapperAddress(
        address _nameWrapperAddress
    ) external onlyOwner {
        nameWrapper = INameWrapper(_nameWrapperAddress);
    }
}
