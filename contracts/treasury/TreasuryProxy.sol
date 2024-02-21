// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract TreasuryProxy is Ownable {
    address payable public treasury;

    constructor(address payable _treasury, address _owner) Ownable(_owner) {
        treasury = _treasury;
    }

    receive() external payable {}

    function withdraw() external onlyOwner {
        (bool sent, ) = address(treasury).call{value: address(this).balance}(
            ""
        );
        require(sent, "Transfer to treasury failed");
    }

    function setTreasury(address payable _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
