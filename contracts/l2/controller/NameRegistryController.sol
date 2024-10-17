// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignatureVerifier} from "./SignatureVerifier.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {RegistryMinter} from "./RegistryMinter.sol";
import {RegistryFactory} from "./RegistryFactory.sol";
import {RegistryExpiryExtender} from "./RegistryExpiryExtender.sol";
import {IRegistryEmitter} from "../registries/IRegistryEmitter.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";
import {IRegistryControllerProxy} from "./RegistryControllerProxy.sol";
import {ControllerBase} from "./ControllerBase.sol";
import "../Types.sol";

/**
 * @title NameRegistryController
 * @dev A registry controller contract responsible for minting subnames, deploying registries,
 * and extending the expiry of existing registries. It verifies off-chain signatures before performing these actions.
 * This contract integrates with several other contracts for its functionalities:
 * - SignatureVerifier: Verifies signatures from off-chain backend
 * - RegistryMinter: Handles the minting of new subnames
 * - RegistryFactory: Handles the deployment of new name registries
 * - RegistryExpiryExtender: Extends the expiry of registered names
 */
contract NameRegistryController is
    Ownable,
    SignatureVerifier,
    RegistryMinter,
    RegistryFactory,
    RegistryExpiryExtender
{
    constructor(
        address _verifier,
        address _treasury,
        address _tokenMetadata,
        address _registryResolver,
        address _emitter,
        address _resolver,
        address _controllerProxy
    )
        ControllerBase(
            _verifier,
            _treasury,
            _tokenMetadata,
            _registryResolver,
            _emitter,
            _resolver,
            _controllerProxy
        )
    {}

    /**
     * @dev Mints a new subname if the provided context and signature are valid.
     * @param context Minting context containing details of the subname to be minted
     * @param signature Signature from the off-chain backend to verify the context
     * @param resolverData Optional resolver data
     * @param extraData Additional data
     */
    function mint(
        MintContext memory context,
        bytes memory signature,
        bytes[] memory resolverData,
        bytes calldata extraData
    ) external payable {
        verifyMintContextSignature(context, signature);
        _mint(context, resolverData, extraData);
    }

    /**
     * @dev Deploys a new registry if the provided context and signature are valid.
     * @param context Factory context containing details for the registry to be deployed
     * @param signature Signature from the off-chain backend to verify the context
     */
    function deploy(
        FactoryContext memory context,
        bytes memory signature,
        bytes[] memory resolverData
    ) external {
        verifyFactoryContextSignature(context, signature);
        _deploy(context, resolverData);
    }

    /**
     * @dev Extends the expiry of an existing registry if the provided context and signature are valid.
     * @param context Expiry extension context containing details for the registry expiry to be extended
     * @param signature Signature from the off-chain backend to verify the context
     */
    function extendExpiry(
        ExtendExpiryContext memory context,
        bytes memory signature
    ) external payable {
        verifyExtendExpiryContextSignature(context, signature);
        _extendExpiry(context);
    }
}
