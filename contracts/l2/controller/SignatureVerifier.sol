// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Types.sol";

error InvalidSignature(address);

contract SignatureVerifier is EIP712 {
    event VerifierSet(address);

    address verifier;
    constructor(
        address _verifier
    ) EIP712("namespace", "1") {
        verifier = _verifier;
        emit VerifierSet(_verifier);
    }

    function verifyFactoryContextSignature(
        FactoryContext memory context,
        bytes memory signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    FACTORY_CONTEXT,
                    keccak256(abi.encodePacked(context.tokenName)),
                    keccak256(abi.encodePacked(context.tokenSymbol)),
                    keccak256(abi.encodePacked(context.label)),
                    keccak256(abi.encodePacked(context.TLD)),
                    context.owner,
                    context.parentControl,
                    context.expirableType
                )
            )
        );
        _verifySignature(digest, signature);
    }

    function verifyMintContextSignature(
        MintContext memory context,
        bytes memory signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINT_CONTEXT,
                    keccak256(abi.encodePacked(context.label)),
                    context.parentNode,
                    context.owner,
                    context.price,
                    context.fee,
                    context.paymentReceiver,
                    context.expiry
                )
            )
        );
        _verifySignature(digest, signature);
    }

    function verifyExtendExpiryContextSignature(
        ExtendExpiryContext memory context,
        bytes memory signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EXTEND_EXPIRY_CONTEXT,
                    context.node,
                    context.expiry,
                    context.price,
                    context.fee,
                    context.paymentReceiver
                )
            )
        );
        _verifySignature(digest, signature);
    }

    function _verifySignature(
        bytes32 digest,
        bytes memory signature
    ) internal view {
        address exctractedSigner = ECDSA.recover(digest, signature);
        if (exctractedSigner != verifier) {
            revert InvalidSignature(exctractedSigner);
        }
    }

    function _setVerifier(address newVerifier) internal virtual {
        verifier = newVerifier;
        emit VerifierSet(newVerifier);
    }
}
