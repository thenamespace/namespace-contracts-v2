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

    address private verifier;
    address private pendingVerifier;
    address[] private verifierApprovals;

    mapping(bytes32 => bool) usedSignatures;

    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address resolver,address subnameOwner,uint32 fuses,uint256 mintPrice,uint256 mintFee)"
        );

    constructor(
        INameWrapper _nameWrapper,
        address _controller,
        address _verifier
    ) Controllable(_controller) EIP712("namespace", "1") {
        require(_controller != _verifier, "Verifier can't be controller");

        nameWrapper = _nameWrapper;
    }

    function setSubnodeRecord(
        MintSubnameContext memory context,
        bytes memory signature,
        uint64 ttl,
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
                ttl,
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

    function setVerifier(address _verifier) external {
        require(!controllers[_verifier], "Verifier can't be controller");

        // when verifier gives the first approval
        if (msg.sender == verifier && verifierApprovals.length == 0) {
            verifierApprovals[0] = msg.sender;
            pendingVerifier = _verifier;
            return;
        }

        // when verfier gives the second approval
        if (
            msg.sender == verifier &&
            verifierApprovals.length == 1 &&
            verifierApprovals[0] != msg.sender
        ) {
            require(
                _verifier == pendingVerifier,
                "Different verifier provided"
            );
            verifier = _verifier;
            delete pendingVerifier;
            delete verifierApprovals;
            return;
        }

        // when controller gives the first approval
        if (controllers[msg.sender] && verifierApprovals.length == 0) {
            verifierApprovals[0] = msg.sender;
            pendingVerifier = _verifier;
            return;
        }

        // when controller gives the second approval
        if (
            controllers[msg.sender] &&
            verifierApprovals.length == 1 &&
            verifierApprovals[0] != msg.sender
        ) {
            require(
                _verifier == pendingVerifier,
                "Different verifier provided"
            );
            verifier = _verifier;
            delete pendingVerifier;
            delete verifierApprovals;
            return;
        }

        revert PermissionDenied("Setting the verifier denied");
    }
}
