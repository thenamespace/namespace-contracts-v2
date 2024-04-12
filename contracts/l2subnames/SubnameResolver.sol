//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

// In progress
// Should we use the existing ENS resolver or is that overkill?
import {ISubnameRegistar} from "./SubnameRegistar.sol";

contract SubnameResolver {
    mapping(bytes32 => mapping(string => string)) addresses;
    mapping(bytes32 => mapping(string => string)) texts;
    mapping(bytes32 => string) contentHash;

    event TextChanged(
        bytes32 node,
        string key,
        string value
    );

    event AddrChanged(
        bytes32 node,
        string coinType,
        string value
    );

    modifier onlyNameOwner(bytes32 node) {
        require(registar.ownerOf(uint256(node)) == msg.sender);
        _;
    }

    function addr(
        bytes32 node,
        string calldata coinType
    ) public view returns (string memory) {
        return addresses[node][coinType];
    }

    function addr(bytes32 node) public view returns (string memory) {
        return addresses[node]["60"];
    }

    function text(
        bytes32 node,
        string calldata key
    ) public view returns (string memory) {
        return texts[node][key];
    }

    function setAddr(
        bytes32 node,
        string memory coinType,
        string memory value
    ) public onlyNameOwner(node) {
        addresses[node][coinType] = value;

        emit AddrChanged(node, coinType, value);
    }

    function setText(
        bytes32 node,
        string memory key,
        string memory value
    ) public onlyNameOwner(node) {
        texts[node][key] = value;

        emit TextChanged(node, key, value);
    }

}
