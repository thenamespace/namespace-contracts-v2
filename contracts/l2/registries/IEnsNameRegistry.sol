// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../Types.sol";

error InvalidExpiry(uint256, string);
error NodeTaken(bytes32, string);
error NodeNotControllable();
error NodeNotFound(bytes32);

uint8 constant TOKEN_NOT_SET = 0;
uint8 constant TOKEN_VALID = 1;
uint8 constant TOKEN_INVALID = 2;

struct RegistryConfig {
    ParentControlType parentControlType;
    ExpirableType expirableType;
    string tokenName;
    string tokenSymbol;
    address tokenMetadataAddress;
    address tokenOwner;
    bytes32 namehash;
    address emitter;
}

interface IEnsNameRegistry {
    //ERC720 functions
    function ownerOf(uint256 tokenId) external view returns (address);
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;

    // Ens related functions
    function register(
        string[] memory labels,
        address owner,
        uint256 expiry
    ) external returns (bytes32);
    function register(
        string memory label,
        address owner,
        uint256 expiration
    ) external returns (bytes32);
    function setExpiry(bytes32 node, uint256 expiration) external;
    function registryNameNode() external view returns (bytes32);
    function burn(bytes32 node) external;
}
