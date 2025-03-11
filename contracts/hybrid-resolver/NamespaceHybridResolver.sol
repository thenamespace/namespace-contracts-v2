// @author artii.eth
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IExtendedResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IExtendedResolver.sol";
import {BytesUtils} from "@ensdomains/ens-contracts/contracts/utils/BytesUtils.sol";
import {EnsResolverBase} from "./EnsResolverBase.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {OffchainResolver} from "./OffchainResolver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";

contract NamespaceHybridResolver is
    IExtendedResolver,
    EnsResolverBase,
    OffchainResolver
{
    using BytesUtils for bytes;

    address public defaultFallbackResolver;
    mapping(bytes32 => address) public fallbackResolvers;
    mapping(bytes32 => bool) private emptyResponseHashes;
    mapping(bytes32 => ResolutionConfig) public configs;
    mapping(uint => bool) supportedResolutionTypes;
    mapping(uint => string[]) public resolutionUrls;

    event ResolutionConfigChanged(bytes32 node, uint prevType, uint newType);
    event FallbackResolverSet(bytes32 node, address newResolver);
    event ResolutionUrlsChanged(uint resolutionType, string[] urls);

    constructor(
        address[] memory _signers,
        address ens,
        address nameWrapper,
        address _fallbackResolver
    )
        Ownable(_msgSender())
        EnsResolverBase(ens, nameWrapper)
        OffchainResolver(_signers)
    {
        emptyResponseHashes[
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
        ] = true;
        emptyResponseHashes[
            0x569e75fc77c1a856f6daaf9e69d8a9566ca34aa47f9133711ce065a571af0cfd
        ] = true;

        supportedResolutionTypes[OFFCHAIN_DB_RESOLUTION] = true;
        supportedResolutionTypes[BASE_RESOLUTION] = true;
        supportedResolutionTypes[OP_RESOLUTION] = true;

        defaultFallbackResolver = _fallbackResolver;
    }

    function resolve(
        bytes memory dnsName,
        bytes memory data
    )
        public
        view
        override(IExtendedResolver, EnsResolverBase)
        returns (bytes memory)
    {
        bytes32 node = dnsName.namehash(0);
        if (isNameOnchain(node) && !configs[node].resolveOffchain) {
            return resolveOnchain(node, data);
        }

        resolveOffchain(dnsName, data);
    }

    function resolveOffchain(
        bytes memory dnsName,
        bytes memory data
    ) internal view {
        // Finding the configured resultion type for provided name
        // and default to offchain_db_resolution if its not set by a name owner
        uint resolutionType = getResolutionConfigurationForName(dnsName);
        if (resolutionType == 0) {
            resolutionType = OFFCHAIN_DB_RESOLUTION;
        }

        string[] memory resolutionsUrls = resolutionUrls[resolutionType];
        require(resolutionsUrls.length > 0, "No resoultion urls found");

        _resolveOffchain(dnsName, data, resolutionsUrls);
    }

    function resolveOnchain(
        bytes32 node,
        bytes memory data
    ) internal view returns (bytes memory) {
        // first we will try to resolve the request on current smart contract
        (bool success, bytes memory result) = address(this).staticcall(data);

        if (success && !isEmptyResponse(result)) {
            return result;
        }

        // We will then try to resolve data from the configured fallback resolver
        // this was set so that we do not need to transfer records.
        // if the fallback resolver was not set for name, we'll default to
        // current ENS Public resolver
        address fallbackResolver = getFallbackResolver(node);
        (bool fallbackSuccess, bytes memory fallbackResult) = address(
            fallbackResolver
        ).staticcall(data);

        require(
            fallbackSuccess,
            "Could not query the fallback resolver contract"
        );

        return fallbackResult;
    }

    function getFallbackResolver(bytes32 node) internal view returns (address) {
        address fallbackResolver = fallbackResolvers[node];
        return
            fallbackResolver == address(0)
                ? defaultFallbackResolver
                : fallbackResolver;
    }

    function setResolutionType(
        bytes32 node,
        uint newResolutionType
    ) public isNodeOwner(node) {
        require(
            supportedResolutionTypes[newResolutionType],
            "Unsupported resolution type provided"
        );

        uint prevResolutionType = configs[node].resolutionType;
        configs[node].resolutionType = newResolutionType;
        emit ResolutionConfigChanged(
            node,
            prevResolutionType,
            newResolutionType
        );
    }

    function setFallbackResolver(
        bytes32 node,
        address fallbackResolver
    ) public isNodeOwner(node) {
        require(
            fallbackResolvers[node] != fallbackResolver,
            "Same fallback resolver already set"
        );

        fallbackResolvers[node] = fallbackResolver;
        emit FallbackResolverSet(node, fallbackResolver);
    }

    function isEmptyResponse(
        bytes memory response
    ) internal view returns (bool) {
        bytes32 responseHash = keccak256(response);
        return emptyResponseHashes[responseHash];
    }

    function isNameOnchain(bytes32 node) internal view returns (bool) {
        // Subnames which are resolvable offchain/l2 will not have
        // a resolver set, since they do not exist on L1
        return ens.resolver(node) != address(0);
    }

    function extractDnsParent(
        bytes memory dnsName
    ) internal pure returns (bytes memory) {
        uint256 idx = 0;

        // Find the first label's length
        uint256 labelLength = uint8(dnsName[idx]);

        // Advance the index to skip the first label and its length byte
        idx += labelLength + 1;

        // Create a new `bytes` array for the remainder
        bytes memory parent = new bytes(dnsName.length - idx);
        for (uint256 i = 0; i < parent.length; i++) {
            parent[i] = dnsName[idx + i];
        }

        return parent;
    }

    function getResolutionConfigurationForName(
        bytes memory dnsName
    ) internal view returns (uint) {
        bytes memory current = dnsName;
        bytes32 nameHash = current.namehash(0);

        while (nameHash != bytes32(0)) {
            if (configs[nameHash].resolutionType != 0) {
                return configs[nameHash].resolutionType;
            } else {
                current = extractDnsParent(current);
                nameHash = current.namehash(0);
            }
        }
        return 0;
    }

    function setResolutionUrls(
        uint256 resolutionType,
        string[] memory urls
    ) public onlyOwner {
        resolutionUrls[resolutionType] = urls;
        emit ResolutionUrlsChanged(resolutionType, urls);
    }

    function setSupportedResolutionType(
        uint resolutionType,
        bool supported
    ) public onlyOwner {
        supportedResolutionTypes[resolutionType] = supported;
    }

    function setEmptyResponse(bytes32 hash, bool value) public onlyOwner {
        emptyResponseHashes[hash] = value;
    }

    function setDefaultFallbackResolver(
        address _fallbackResolver
    ) public onlyOwner {
        defaultFallbackResolver = _fallbackResolver;
    }
}
