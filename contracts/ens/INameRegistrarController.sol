// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct Price {
    uint256 base;
    uint256 premium;
}

interface IETHRegistrarController {
    function rentPrice(
        string memory,
        uint256
    ) external view returns (Price memory);

    function available(string memory) external returns (bool);

    function makeCommitment(
        string memory,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint16
    ) external pure returns (bytes32);

    function commit(bytes32) external;

    function register(
        string calldata,
        address,
        uint256,
        bytes32,
        address,
        bytes[] calldata,
        bool,
        uint16
    ) external payable;

    function renew(string calldata, uint256) external payable;
}
