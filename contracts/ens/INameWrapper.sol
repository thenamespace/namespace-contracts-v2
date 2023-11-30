//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

interface INameWrapper {
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
