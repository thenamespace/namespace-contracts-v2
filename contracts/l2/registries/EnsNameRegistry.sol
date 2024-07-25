// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EnsUtils} from "../utils/EnsUtils.sol";
import {Controllable} from "../../controllers/Controllable.sol";
import {IRegistryEmitter} from "./IRegistryEmitter.sol";
import "./IEnsNameRegistry.sol";

/**
 * @title EnsNameRegistry
 * @dev Contract for managing Ethereum Name Service (ENS) subnames.
 * Extends ERC721 for NFT-like functionality and includes name registration, ownership,
 * expiry management, and metadata.
 */
contract EnsNameRegistry is ERC721, Controllable {
    mapping(bytes32 => uint256) public expiries;
    mapping(bytes32 => address) public resolvers;
    RegistryConfig public config;
    IRegistryEmitter emitter;

    modifier registryTokenOwner() {
        require(
            ownerOf(uint256(registryNameNode())) == _msgSender(),
            "Not allowed"
        );
        _;
    }

    constructor(
        RegistryConfig memory _config
    ) ERC721(_config.tokenName, _config.tokenSymbol) {
        emitter = IRegistryEmitter(_config.emitter);
        config = _config;
        _mintNameToken(
            _config.namehash,
            _config.tokenOwner,
            _config.tokenResolver
        );
    }

    /**
     * @dev Registers an ENS subname with multiple labels.
     * Allows for minting subname with multiple levels (e.g., lvl3.lvl2.lvl1.example.eth).
     * @param labels Array of subname labels.
     * @param owner Address of the new subname owner.
     * @param resolver Address of the resolver contract where records are stored.
     * @param expiry Optional expiry timestamp for the subname.
     * @return bytes32 Hash representation of the registered subname.
     */
    function register(
        string[] memory labels,
        address owner,
        address resolver,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        require(labels.length > 0 && labels.length < 10, "Labels length invalid");

        if (labels.length > 1) {
            string memory _label = "";
            bytes32 node = registryNameNode();
            for (uint i = 0; i < labels.length; i++) {
                node = EnsUtils.namehash(node, labels[i]);
                _label = string.concat(_label, labels[i]);

                if (i < labels.length - 1) {
                    _label = string.concat(_label, ".");
                }
            }
            return _register(_label, node, owner, resolver, expiry);
        } else {
            bytes32 node = EnsUtils.namehash(registryNameNode(), labels[0]);
            return _register(labels[0], node, owner, resolver, expiry);
        }
    }

    /**
     * @dev Registers a single-level ENS subname.
     * Handles simple subnames (e.g., subname.example.eth).
     * @param label Single subname label.
     * @param owner Address of the new subname owner.
     * @param resolver Address of the resolver contract where records are stored.
     * @param expiry Optional expiry timestamp for the subname.
     * @return bytes32 Hash representation of the registered subname.
     */
    function register(
        string memory label,
        address owner,
        address resolver,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        bytes32 node = EnsUtils.namehash(registryNameNode(), label);
        return _register(label, node, owner, resolver, expiry);
    }

    /**
     * @dev Sets or updates the expiry date of an ENS name.
     * Ensures the expiry date is valid and not in the past.
     * @param node Hash representation of the ENS name.
     * @param expiry New expiry timestamp.
     */
    function setExpiry(bytes32 node, uint256 expiry) external onlyController {
        _isValidExpiry(expiry);

        uint256 tokenId = uint256(node);
        if (ownerOf(tokenId) == address(0)) {
            revert NodeNotFound(node);
        }

        expiries[node] = expiry;
        emitter.emitExpirySet(node, expiry);
    }

    /**
     * @dev Burns (removes) an ENS name if allowed by the controllable fuse.
     * Deletes the resolver and expiry associated with the name.
     * @param node Hash representation of the ENS name.
     */
    function burn(bytes32 node) public registryTokenOwner {
        if (_isControllable()) {
            _burn(uint256(node));
            delete resolvers[node];
            delete expiries[node];

            emitter.emitNodeBurned(node, registryNameNode(), _msgSender());
        } else {
            revert NodeNotControllable();
        }
    }

    /**
     * @dev Burning controllable fuse, registry owner loses ability
     * to burn subnames
     */
    function burnControllableFuse() public registryTokenOwner {
        if (_isControllable()) {
            config.parentControlType = ParentControlType.NonControllable;
        }
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        config.metadataUri = _baseUri;
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipWithExpiry(tokenId);
    }

    function registryNameNode() public view returns (bytes32) {
        return config.namehash;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);

        if (from != address(0)) {
            emitter.emitNodeTransfer(
                bytes32(tokenId),
                registryNameNode(),
                from,
                to
            );
        }
    }

    function _ownershipWithExpiry(
        uint256 tokenId
    ) internal view returns (address) {
        bytes32 node = bytes32(tokenId);
        if (_isExpired(node)) {
            return address(0);
        }

        return _ownerOf(tokenId);
    }

    function _register(
        string memory label,
        bytes32 node,
        address owner,
        address resolver,
        uint256 expiry
    ) internal returns (bytes32) {
        _isValidExpiry(expiry);

        uint256 token = uint256(node);

        if (_ownershipWithExpiry(token) != address(0)) {
            revert NodeTaken(node, label);
        }

        address previousOwner = _ownerOf(token);
        if (previousOwner != address(0)) {
            _burn(token);
        }

        resolvers[node] = resolver;
        if (_isExpirable()) {
            expiries[node] = expiry;
        }

        _mint(owner, token);

        emitter.emitNodeCreated(
            label,
            node,
            registryNameNode(),
            expiry,
            resolver
        );

        return node;
    }

    function _mintNameToken(
        bytes32 node,
        address owner,
        address resolver
    ) internal {
        uint256 tokenId = uint256(node);
        _mint(owner, tokenId);

        resolvers[node] = resolver;
        expiries[node] = type(uint256).max;
    }

    function _isExpired(bytes32 node) public view returns (bool) {
        if (!_isExpirable()) {
            return false;
        }

        return expiries[node] < block.timestamp;
    }

    function _isExpirable() internal view returns (bool) {
        return config.expirableType == ExpirableType.Expirable;
    }

    function _isControllable() internal view returns (bool) {
        return config.parentControlType == ParentControlType.Controllable;
    }

    function _isValidExpiry(uint256 expiration) internal view {
        if (_isExpirable() && expiration < block.timestamp) {
            revert InvalidExpiry(
                expiration,
                "Expiry should be greather than block.timestamp"
            );
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return config.metadataUri;
    }
}
