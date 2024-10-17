// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenMetadata is Ownable {
    string public metadataURI;

    event MetadataUriChanged(string metadataUri, address executor);

    constructor(string memory _metadataURI) Ownable(_msgSender()) {
        metadataURI = _metadataURI;
    }

    function getMetadataURI() public view returns (string memory) {
        return metadataURI;
    }

    function setMetadataURI(string memory _metadataURI) public onlyOwner {
        metadataURI = _metadataURI;
        emit MetadataUriChanged(_metadataURI, _msgSender());
    }
}
