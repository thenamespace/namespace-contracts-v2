// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Controllable} from "../../controllers/Controllable.sol";
import "./IRegistryEmitter.sol";

contract RegistryEmitter is Controllable, IRegistryEmitter {
    mapping(address => bool) approvedEmitters;

    event EmitterChanged(address emitter, bool value);

    modifier isApprovedEmitter() {
        require(approvedEmitters[_msgSender()], "Not Approved Emitter");
        _;
    }

    event NodeTransfer(
        bytes32 node,
        bytes32 parentNode,
        address from,
        address to
    );
    event NodeBurned(bytes32 node, bytes32 parentNode, address executor);
    event NodeCreated(
        string label,
        bytes32 node,
        bytes32 indexed parentNode,
        uint256 expiry
    );
    event DelegateChanged(address delegate, bool approved);
    event ExpirySet(bytes32 node, uint256 expiry);

    function emitNodeTransfer(
        bytes32 node,
        bytes32 parentNode,
        address from,
        address to
    ) external isApprovedEmitter {
        emit NodeTransfer(node, parentNode, from, to);
    }

    function emitNodeBurned(
        bytes32 node,
        bytes32 parentNode,
        address executor
    ) external isApprovedEmitter {
        emit NodeBurned(node, parentNode, executor);
    }

    function emitNodeCreated(
        string memory label,
        bytes32 node,
        bytes32 parentNode,
        uint256 expiry
    ) external isApprovedEmitter {
        emit NodeCreated(label, node, parentNode, expiry);
    }

    function emitExpirySet(
        bytes32 node,
        uint256 expiry
    ) external isApprovedEmitter {
        emit ExpirySet(node, expiry);
    }

    function emitDelegateChanged(
        address delegate,
        bool approved
    ) external isApprovedEmitter {
        emit DelegateChanged(delegate, approved);
    }

    function setApprovedEmitter(
        address emitter,
        bool value
    ) external onlyController {
        approvedEmitters[emitter] = value;
        emit EmitterChanged(emitter, value);
    }
}
