// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./Types.sol";
import {NamespaceHybridResolver} from "./NamespaceHybridResolver.sol";

contract ResolverDeployer {
    address public hybridResolver;
    constructor(
        address owner,
        address[] memory signers,
        address ens,
        address nameWrapper,
        address fallbackResolver,
        ResolutionUrls[] memory _urls
    ) {
        NamespaceHybridResolver _hybridResolver = new NamespaceHybridResolver(
            signers,
            ens,
            nameWrapper,
            fallbackResolver
        );
        for (uint i = 0; i < _urls.length; i++) {
            _hybridResolver.setResolutionUrls(
                _urls[i].resolutionType,
                _urls[i].urls
            );
        }
        _hybridResolver.transferOwnership(owner);
        hybridResolver = address(_hybridResolver);
    }
}
