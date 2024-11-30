// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

uint constant OFFCHAIN_DB_RESOLUTION = 9999;
uint constant BASE_RESOLUTION = 8453;
uint constant OP_RESOLUTION = 10;

struct ResolutionConfig {
    bool resolveOffchain;
    uint resolutionType;
}

struct ResolutionUrls {
    uint resolutionType;
    string[] urls;
}

interface ITrustlessResolver {
    function resolve(
        bytes memory dnsName,
        bytes memory data,
        uint chainId
    ) external view returns (bytes memory);
}
