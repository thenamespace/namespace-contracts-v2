// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Types.sol";

error InvalidSignature(address);
error SignatureExpired();
error NotVerifiedMinter();

contract SignatureVerifier is EIP712 {
    event VerifierChanged(address verifier, bool allowed);
    mapping(address => bool) verifiers;

    constructor(address _verifier) EIP712("namespace", "1") {
        verifiers[_verifier] = true;
        emit VerifierChanged(_verifier, true);
    }

    function verifyFactoryContextSignature(
        FactoryContext memory context,
        bytes memory signature
    ) internal view {
        _verifySignatureExpiry(context.signatureExpiry);
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
                    context.expirableType,
                    context.signatureExpiry
                )
            )
        );
        _verifySignature(digest, signature);
    }

    function verifyMintContextSignature(
        MintContext memory context,
        bytes memory signature
    ) internal view {
        _verifySignatureExpiry(context.signatureExpiry);

        if (context.verifiedMinter != msg.sender) {
            revert NotVerifiedMinter();
        }

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
                    context.expiry,
                    context.signatureExpiry,
                    context.verifiedMinter
                )
            )
        );
        _verifySignature(digest, signature);
    }

    function verifyExtendExpiryContextSignature(
        ExtendExpiryContext memory context,
        bytes memory signature
    ) internal view {
        _verifySignatureExpiry(context.signatureExpiry);
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    EXTEND_EXPIRY_CONTEXT,
                    context.node,
                    context.expiry,
                    context.price,
                    context.fee,
                    context.paymentReceiver,
                    context.signatureExpiry
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
        if (!verifiers[exctractedSigner]) {
            revert InvalidSignature(exctractedSigner);
        }
    }

    function _verifySignatureExpiry(uint256 signatureExpiry) internal view {
        if (signatureExpiry <= block.timestamp) {
            revert SignatureExpired();
        }
    }

    function _setVerifier(address newVerifier, bool allowed) internal virtual {
        verifiers[newVerifier] = allowed;
        emit VerifierChanged(newVerifier, allowed);
    }
}
