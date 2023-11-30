//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./ens/INameWrapper.sol";
import "./Types.sol";
import "./controllers/Controllable.sol";
import "./NamespaceEmitter.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract NamespaceMinter is Controllable, EIP712("namespace", "1") {
    address private verifier;
    address private treasury;
    INameWrapper wrapperDelegate;
    NamespaceEmitter emitter;

    constructor(
        address _verifier,
        address _treasury,
        address _controller,
        INameWrapper _wrapperDelegate
    ) {
        wrapperDelegate = _wrapperDelegate;
        verifier = _verifier;
        treasury = _treasury;
        setController(_controller);
    }

    //@dev Event emmited when subname gets minted
    event SubnameMinted(
        bytes32 indexed parentNode,
        string label,
        uint256 price,
        address indexed paymentReceiver,
        address sender,
        address subnameOwner
    );

    function mintUnsafe(
        MintSubnameContext memory mintContext,
        bytes memory signature
    ) external payable {
        _verify(mintContext, signature);
        _mint(mintContext);
        _transferFunds(mintContext);
        _emit(mintContext);
    }

    function _transferFunds(MintSubnameContext memory context) internal {
        require(
            msg.value >= context.mintPrice + context.mintFee,
            "Inssuficient funds"
        );
        payable(context.paymentReceiver).transfer(context.mintPrice);
        payable(treasury).transfer(context.mintFee);
    }

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

    function _verify(
        MintSubnameContext memory context,
        bytes memory signature
    ) internal {
        bytes32 _encodedData = keccak256(
            abi.encodePacked(
                context.subnameLabel,
                context.parentNode,
                context.resolver,
                context.subnameOwner,
                context.fuses,
                context.mintPrice,
                context.mintFee,
                context.paymentReceiver
            )
        );

        string memory _parameters = 
            "MintContext(string subnameLabel, bytes32 parentNode, address resolver, address subnameOwner, uint64 fuses, uint256 mintPrice, uint256 mintFee, address paymentReceiver)";
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(
                _parameters,
                context.subnameLabel,
                context.parentNode,
                context.resolver,
                context.subnameOwner,
                context.fuses,
                context.mintPrice,
                context.mintFee,
                context.paymentReceiver
            ))
        );

        address signer = ECDSA.recover(digest, signature);
        require(signer == verifier, "Signature cannot be verified.");
    }

    function _emit(MintSubnameContext memory context) internal {
        emitter.emitSubnameMinted(
            context.subnameLabel,
            context.parentNode,
            context.mintPrice,
            context.paymentReceiver,
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
