//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

interface INameWrapper {
    error Unauthorised(bytes32 node, address addr);
    error IncompatibleParent();
    error IncorrectTokenType();
    error LabelMismatch(bytes32 labelHash, bytes32 expectedLabelhash);
    error LabelTooShort();
    error LabelTooLong(string label);
    error IncorrectTargetOwner(address owner);
    error CannotUpgrade();
    error OperationProhibited(bytes32 node);
    error NameIsNotWrapped();
    error NameIsStillExpired();

    function ownerOf(uint256 id) external view returns (address owner);

    function setSubnodeRecord(
        bytes32 node,
        string calldata label,
        address owner,
        address resolver,
        uint64 ttl,
        uint32 fuses,
        uint64 expiry
    ) external returns (bytes32);
}
