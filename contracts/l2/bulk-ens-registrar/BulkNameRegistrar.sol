// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../ens/INameRegistrarController.sol";
import "./Types.sol";

contract BulkNameRegistrar is Ownable {
    uint256 fee_percent;
    IETHRegistrarController controller;

    constructor(
        address _controller,
        address _owner,
        uint256 _fee_percent
    ) Ownable(_owner) {
        controller = IETHRegistrarController(_controller);
        require(_fee_percent > 0 && _fee_percent < 1000, "Invalid fees");
    }

    function bulkCommitment(bytes32[] memory commitments) external {
        for (uint i = 0; i < commitments.length; i++) {
            controller.commit(commitments[i]);
        }
    }

    function bulkRegister(RegistrationContext[] memory ctx) external payable {
        uint256 totalPrice = 0;
        for (uint i = 0; i < ctx.length; i++) {
            totalPrice += ctx[i].registrationPrice;
            _registerName(ctx[i]);
        }

        if (fee_percent > 0) {
            require(
                totalPrice + calculateFee(totalPrice) >= msg.value,
                "Insufficient funds"
            );
        }
    }

    function _registerName(RegistrationContext memory ctx) internal {
         controller.register{value: ctx.registrationPrice}(
                ctx.name,
                ctx.owner,
                ctx.duration,
                ctx.secret,
                ctx.resolver,
                ctx.data,
                ctx.reverseRecord,
                ctx.ownerControlledFuses
            );
    }

    function getPriceWithFees(
        uint256 totalPrice
    ) external view returns (uint256) {
        if (fee_percent == 0) {
            return totalPrice;
        }
        return totalPrice + calculateFee(totalPrice);
    }

    function calculateFee(uint256 total) internal view returns (uint256) {
        return (total * fee_percent) / 1000;
    }

    function withdrawFees(address treasury) external onlyOwner {
        payable(treasury).transfer(address(this).balance);
    }

    function setFees(uint256 _fee_percent) external onlyOwner {
        require(_fee_percent < 1000, "Invalid fees");
        fee_percent = _fee_percent;
    }
}
