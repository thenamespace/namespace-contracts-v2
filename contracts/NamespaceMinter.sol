//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./ens/INameWrapper.sol";
import "./Types.sol";
import "./controllers/Controllable.sol";
import "./INamespaceEmitter.sol";
import "./INamespaceRegistry.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error InvalidSignature();
error NameNotListed(bytes32 node);
error SignatureAlreadyUsed();
error NotEnoughFunds(uint256 current, uint256 expected);

contract NamespaceMinter is Controllable, EIP712 {
    address private verifier;
    address private treasury;
    INameWrapper wrapperDelegate;
    INamespaceEmitter emitter;
    INamespaceRegistry registry;
    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address resolver,address subnameOwner,uint32 fuses,uint256 mintPrice,uint256 mintFee)"
        );

    mapping(bytes32 => bool) usedSignatures;

    constructor(
        address _verifier,
        address _treasury,
        address _controller,
        INameWrapper _wrapperDelegate,
        INamespaceEmitter _emitter,
        INamespaceRegistry _registry
    ) Controllable(_controller) EIP712("namespace", "1") {
        wrapperDelegate = _wrapperDelegate;
        verifier = _verifier;
        treasury = _treasury;
        emitter = _emitter;
        registry = _registry;
    }

    // @context
    // @param 
    function mint(
        MintSubnameContext memory context,
        bytes memory signature
    ) external payable {
        bytes32 signatureHash = keccak256(signature);

        if (usedSignatures[signatureHash]) {
            revert SignatureAlreadyUsed();
        }

        ListedENSName memory listing = registry.getListing(context.parentNode);
        if (!listing.isListed) {
            revert NameNotListed(context.parentNode);
        }

        if (_extractSigner(context, signature) != verifier) {
            revert InvalidSignature();
        }

        uint256 totalPrice = context.mintFee + context.mintPrice;
        if (msg.value < totalPrice) {
            revert NotEnoughFunds(msg.value, totalPrice);
        }

        usedSignatures[signatureHash] = true;
        _mint(context);
        _transferFunds(
            listing.paymentReceiver,
            context.mintPrice,
            context.mintFee
        );
    }

    function _transferFunds(
        address paymentReceiver,
        uint256 mintPrice,
        uint256 mintFee
    ) internal {
        payable(paymentReceiver).transfer(mintPrice);
        payable(treasury).transfer(mintFee);
    }

    // curently, all the info required for minting is calculated offchain and send via parameters with sigature
    // maybe we can store listing prices on chain and use offchain for additional minting condition (whitelistings, reservations, tokenGated)
    function _mint(MintSubnameContext memory context) internal {
        wrapperDelegate.setSubnodeRecord(
            context.parentNode,
            context.subnameLabel,
            context.subnameOwner,
            context.resolver,
            type(uint64).max,
            context.fuses,
            type(uint64).max
        );
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

    function _emit(
        MintSubnameContext memory context,
        address paymentReceiver
    ) internal {
        emitter.emitSubnameMinted(
            context.subnameLabel,
            context.parentNode,
            context.mintPrice,
            paymentReceiver,
            msg.sender,
            context.subnameOwner
        );
    }

    function setTreasury(address _treasury) external onlyController {
        treasury = _treasury;
    }

    function setVerifier(address _verifier) external onlyController {
        verifier = _verifier;
    }

    function withdraw() external onlyController {
        require(address(this).balance > 0, "No funds present.");
        payable(treasury).transfer(address(this).balance);
    }
}
