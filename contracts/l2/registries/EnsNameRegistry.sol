// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {EnsUtils} from "../utils/EnsUtils.sol";
import {Controllable} from "../../controllers/Controllable.sol";
import {IRegistryEmitter} from "./IRegistryEmitter.sol";
import {TokenMetadata} from "./TokenMetadata.sol";
import "./IEnsNameRegistry.sol";

/**
 * @title EnsNameRegistry
 * @dev Contract for managing Ethereum Name Service (ENS) subnames.
 * Extends ERC721 for NFT-like functionality and includes name registration, ownership,
 * expiry management, and metadata.
 */
contract EnsNameRegistry is ERC721, Controllable {
    mapping(bytes32 => uint256) public expiries;
    RegistryConfig public config;
    IRegistryEmitter emitter;
    TokenMetadata tokenMetadata;
    uint public immutable registryVersion = 2;

    mapping(address => uint256[]) _ownedTokens;
    mapping(address => mapping(uint256 token => uint8)) _ownedTokenStatus;

    modifier registryTokenOwner() {
        require(
            ownerOf(uint256(registryNameNode())) == _msgSender(),
            "Not registry token owner"
        );
        _;
    }

    modifier isNotExpired(uint256 tokenId) {
        require(!_isExpired(bytes32(tokenId)), "Node is expired");
        _;
    }

    constructor(
        RegistryConfig memory _config
    ) ERC721(_config.tokenName, _config.tokenSymbol) {
        emitter = IRegistryEmitter(_config.emitter);
        tokenMetadata = TokenMetadata(_config.tokenMetadataAddress);
        config = _config;
        claimRegistryToken();
    }

    /**
     * @dev Registers an ENS subname with multiple labels.
     * Allows for minting subname with multiple levels (e.g., lvl3.lvl2.lvl1.example.eth).
     * @param labels Array of subname labels.
     * @param owner Address of the new subname owner.
     * @param expiry Optional expiry timestamp for the subname.
     * @return bytes32 Hash representation of the registered subname.
     */
    function register(
        string[] memory labels,
        address owner,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        require(
            labels.length > 0 && labels.length < 10,
            "Labels length invalid"
        );

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
            return _register(_label, node, owner, expiry);
        } else {
            bytes32 node = EnsUtils.namehash(registryNameNode(), labels[0]);
            return _register(labels[0], node, owner, expiry);
        }
    }

    /**
     * @dev Registers a single-level ENS subname.
     * Handles simple subnames (e.g., subname.example.eth).
     * @param label Single subname label.
     * @param owner Address of the new subname owner.
     * @param expiry Optional expiry timestamp for the subname.
     * @return bytes32 Hash representation of the registered subname.
     */
    function register(
        string memory label,
        address owner,
        uint256 expiry
    ) external onlyController returns (bytes32) {
        bytes32 node = EnsUtils.namehash(registryNameNode(), label);
        return _register(label, node, owner, expiry);
    }

    /**
     * @dev Sets or updates the expiry date of an ENS name.
     * Ensures the expiry date is valid and not in the past.
     * @param node Hash representation of the ENS name.
     * @param expiry New expiry timestamp.
     */
    function setExpiry(bytes32 node, uint256 expiry) external onlyController {
        uint256 tokenId = uint256(node);

        require(
            node != registryNameNode(),
            "Registry name node is not expirable"
        );

        if (ownerOf(tokenId) == address(0)) {
            revert NodeNotFound(node);
        }

        _setExpiry(node, expiry);
    }

    /**
     * @dev Burns (removes) an ENS name if allowed by the controllable fuse.
     * Deletes the resolver and expiry associated with the name.
     * @param node Hash representation of the ENS name.
     */
    function burn(bytes32 node) public registryTokenOwner {
        if (_isControllable() && node != registryNameNode()) {
            _burn(uint256(node));
            delete expiries[node];
            emitter.emitNodeBurned(node, registryNameNode(), _msgSender());
        } else {
            revert NodeNotControllable();
        }
    }

    /**
     * @dev Burns (removes) (in a bulk) an ENS names if allowed by the controllable fuse.
     * Deletes the expiry associated with the name.
     * @param nodes Hash representation of the ENS name.
     */
    function burnBulk(bytes32[] memory nodes) public registryTokenOwner {
        for (uint i = 0; i < nodes.length; i++) {
            burn(nodes[i]);
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
    ) public override isNotExpired(tokenId) {
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

    function approve(
        address to,
        uint256 tokenId
    ) public override isNotExpired(tokenId) {
        super.approve(to, tokenId);
    }

    function getApproved(
        uint256 tokenId
    ) public view override isNotExpired(tokenId) returns (address) {
        return super.getApproved(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override isNotExpired(tokenId) returns (string memory) {
        return super.tokenURI(tokenId);
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

    function balanceOf(address owner) public view override returns (uint256) {
        if (!_isExpirable()) {
            return super.balanceOf(owner);
        }
        return _balanceOfExpirable(owner);
    }

    function _register(
        string memory label,
        bytes32 node,
        address owner,
        uint256 expiry
    ) internal returns (bytes32) {
        uint256 token = uint256(node);

        if (_ownershipWithExpiry(token) != address(0)) {
            revert NodeTaken(node, label);
        }

        address previousOwner = _ownerOf(token);
        if (previousOwner != address(0)) {
            _burn(token);
        }

        _mint(owner, token);

        if (_isExpirable()) {
            _setExpiry(node, expiry);
        }

        emitter.emitNodeCreated(label, node, registryNameNode(), expiries[node]);

        return node;
    }

    function _setExpiry(bytes32 node, uint256 expiry) internal {
        if (_isExpired(node) || expiries[node] == 0) {
            expiries[node] = block.timestamp + expiry;
        } else {
            expiries[node] += expiry;
        }
        emitter.emitExpirySet(node, expiries[node]);
    }

    function claimRegistryToken() internal {
        uint256 registryTokenId = uint256(config.namehash);

        require(
            _ownerOf(registryTokenId) == address(0),
            "Registry token already claimed"
        );
        expiries[config.namehash] = type(uint256).max;
        _mint(config.tokenOwner, registryTokenId);
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

    function _baseURI() internal view override returns (string memory) {
        return tokenMetadata.getMetadataURI();
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        if (_isExpirable()) {
            // case - token has been minted
            if (previousOwner == address(0)) {
                _addOwnedToken(to, tokenId);
            }

            // case - token has been burned
            if (to == address(0)) {
                _removeOwnedToken(previousOwner, tokenId);
            }

            // case - token has been transfered
            if (
                to != address(0) &&
                previousOwner != address(0) &&
                to != previousOwner
            ) {
                _addOwnedToken(to, tokenId);
                _removeOwnedToken(previousOwner, tokenId);
            }
        }

        return previousOwner;
    }

    function _addOwnedToken(address owner, uint256 tokenId) internal {
        if (_ownedTokenStatus[owner][tokenId] == TOKEN_NOT_SET) {
            _ownedTokens[owner].push(tokenId);
        }
        _ownedTokenStatus[owner][tokenId] = TOKEN_VALID;
    }

    function _removeOwnedToken(address owner, uint256 tokenId) internal {
        _ownedTokenStatus[owner][tokenId] = TOKEN_INVALID;
    }

    function _balanceOfExpirable(address owner) internal view returns (uint256) {
        uint256 balance = 0;
        uint256 ownedTokensLen = _ownedTokens[owner].length;
        for (uint i = 0; i < ownedTokensLen; i++) {
            uint256 currentTokenId = _ownedTokens[owner][i];
            if (
                _ownedTokenStatus[owner][currentTokenId] == TOKEN_VALID &&
                !_isExpired(bytes32(currentTokenId))
            ) {
                balance++;
            }
        }
        return balance;
    }
}
