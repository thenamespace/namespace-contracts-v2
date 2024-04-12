//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Controllable} from "../controllers/Controllable.sol";

interface ISubnameRegistar {
    function mintSubname(
        bytes32 subnameNode,
        address owner,
        address resolver,
        uint64 expiry
    ) public;

    function ownerOf(uint256 tokenId) public view returns (address)
}

contract SubnameRegistar is ERC721, Controllable {
    mapping(bytes32 => address) resolvers;
    mapping(bytes32 => uint64) expirations;

    event ResolverSet(bytes32 indexed subnameNode, address resolver);

    event SubnameMinted(
        bytes32 indexed subnameNode,
        address owner,
        address resolver
    );

    constructor()
        ERC721("NamespaceENSSubname", "ENS")
        Controllable(msg.sender)
    {}

    function mintSubname(
        bytes32 subnameNode,
        address owner,
        address resolver,
        uint64 expiry
    ) external onlyController {

        require(
            expiry > block.timestamp,
            "Expiry must be greater than block timestamp"
        );

        require(_unexpiredOwner(subnameNode) == address(0), "Name already taken");

        resolvers[subnameNode] = resolver;
        expirations[subnameNode] = expiry;

        _mint(owner, uint256(subnameNode));
        emit SubnameMinted(subnameNode, owner, resolver);
    }

    function setResolver(bytes32 subnameNode, address resolver) external {
        require(address(0) != resolver, "Resolver can't be 0 address");

        require(ownerOf(uint256(subnameNode)) == msg.sender, "Unauthorized");

        resolvers[subnameNode] = resolver;

        emit ResolverSet(subnameNode, resolver);
    }

    function ownerOf(uint256 tokenId) public override view virtual returns (address) {
        return _unexpiredOwner(bytes32(tokenId));
    }

    function _unexpiredOwner(bytes32 subnameNode) internal view returns (address) {
    
        if (expirations[subnameNode] < block.timestamp) {
            return address(0);
        }

        return  _requireOwned(uint256(subnameNode));
    }
}
