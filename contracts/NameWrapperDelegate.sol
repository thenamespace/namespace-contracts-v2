//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./ens/INameWrapper.sol";
import "./controllers/Controllable.sol";

contract NameWrapperDelegate is Controllable {
    mapping(address => bool) private accessControl;
    INameWrapper nameWrapper;

    constructor(
        INameWrapper _nameWrapper,
        address _controller
    ) Controllable(_controller) {
        nameWrapper = _nameWrapper;
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
}
