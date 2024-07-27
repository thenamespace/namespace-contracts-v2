// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library EnsUtils {
    function namehash(
        bytes32 parentNode,
        string memory nameLabel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parentNode, labelhash(nameLabel)));
    }

    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }
}
