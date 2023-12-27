//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import {MintSubnameContext} from "./Types.sol";
import "./ens/INameWrapper.sol";
import "./controllers/Controllable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error SignatureAlreadyUsed();
error InvalidSignature();
error PermissionDenied(string message);

contract NameWrapperDelegate is Controllable, EIP712 {
    mapping(address => bool) private accessControl;
    INameWrapper nameWrapper;

    struct ChangeVerifier {
        bool controllerApproval;
        bool verifierApproval;
        address pendingVerifier;
    }

    ChangeVerifier private changeVerifier;

    address private verifier;

    mapping(bytes32 => bool) usedSignatures;

    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address resolver,address subnameOwner,uint32 fuses,uint256 mintPrice,uint256 mintFee)"
        );

    constructor(
        INameWrapper _nameWrapper,
        address _controller,
        address _verifier
    ) Controllable(msg.sender, _controller) EIP712("namespace", "1") {
        require(_controller != _verifier, "Verifier can't be controller");

        nameWrapper = _nameWrapper;
    }

    function setSubnodeRecord(
        MintSubnameContext memory context,
        bytes memory signature,
        uint64 expiry
    ) external onlyController returns (bytes32) {
        bytes32 signatureHash = keccak256(signature);

        if (usedSignatures[signatureHash]) {
            revert SignatureAlreadyUsed();
        }

        if (_extractSigner(context, signature) != verifier) {
            revert InvalidSignature();
        }

        usedSignatures[signatureHash] = true;

        return
            nameWrapper.setSubnodeRecord(
                context.parentNode,
                context.subnameLabel,
                context.subnameOwner,
                context.resolver,
                context.ttl,
                context.fuses,
                expiry
            );
    }

    function setFuses(bytes32 node, uint16 fuse) external onlyController {
        nameWrapper.setFuses(node, fuse);
    }

    function _extractSigner(
        MintSubnameContext memory context,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINT_CONTEXT,
                    keccak256(abi.encodePacked(context.subnameLabel)),
                    context.parentNode,
                    context.resolver,
                    context.subnameOwner,
                    context.fuses,
                    context.mintPrice,
                    context.mintFee
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }

    function ownerOf(uint256 node) external view returns (address) {
        return nameWrapper.ownerOf(node);
    }

    function setVerifier(address _verifier) external {
        require(
            _verifier != address(0) && !controllers[_verifier],
            "Verifier cannot be zero address or controller"
        );

        require(
            msg.sender == verifier || controllers[msg.sender],
            "Operation not permited"
        );

        if (msg.sender == verifier) {
            changeVerifier.verifierApproval = true;
        } else if (controllers[msg.sender]) {
            changeVerifier.controllerApproval = true;
        }

        if (changeVerifier.pendingVerifier == address(0)) {
            changeVerifier.pendingVerifier = _verifier;
        } else if (changeVerifier.pendingVerifier != _verifier) {
            revert PermissionDenied("Verifier missmatch");
        }

        if (
            changeVerifier.verifierApproval && changeVerifier.controllerApproval
        ) {
            verifier = changeVerifier.pendingVerifier;
            delete changeVerifier;
        }
    }
}
