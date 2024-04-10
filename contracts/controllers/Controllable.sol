//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract Controllable is Ownable2Step {
    mapping(address => bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    constructor() Ownable(msg.sender) {}

    modifier onlyController() {
        require(
            controllers[msg.sender],
            "Controllable: Caller is not a controller"
        );
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}
