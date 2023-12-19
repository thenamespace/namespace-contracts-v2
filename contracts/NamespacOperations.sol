//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import "./Types.sol";
import "./controllers/Controllable.sol";
import "./INamespaceRegistry.sol";
import "./ens/INameWrapper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

error InvalidSignature();
error NotNameOwner(address current, address expected);
error NameNotListed(bytes32 node);
error LabelListingNotFound(string nameLabel);
error SignatureAlreadyUsed();
error NotEnoughFunds(uint256 current, uint256 expected);

contract NamespaceOperations is Controllable, EIP712 {
    event NameListed(string nameLabel, bytes32 node, address operator);

    event NameUnlisted(string nameLabel, bytes32 node, address operator);

    event SubnameMinted(
        bytes32 indexed parentNode,
        string label,
        uint256 price,
        address indexed paymentReceiver,
        address sender,
        address subnameOwner
    );

    address private verifier;
    address private treasury;
    address public nameWrapper;
    INamespaceRegistry registry;

    bytes32 private constant ETH_NODE =
        0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address resolver,address subnameOwner,uint32 fuses,uint256 mintPrice,uint256 mintFee)"
        );

    mapping(bytes32 => bool) usedSignatures;

    constructor(
        address _verifier,
        address _treasury,
        address _controller,
        address _nameWrapper
    ) Controllable(_controller) EIP712("namespace", "1") {
        verifier = _verifier;
        treasury = _treasury;
        nameWrapper = _nameWrapper;
    }

    function list(
        string memory ensNameLabel,
        bytes32 nameNode,
        address paymentReceiver
    ) external {
        _isNameOwner(nameNode);

        // CANNOT_UNWRAP needs to be burned to allow minting unruggable subnames
        INameWrapper(nameWrapper).setFuses(nameNode, uint16(CANNOT_UNWRAP));

        registry.set(
            nameNode,
            ListedENSName(ensNameLabel, nameNode, paymentReceiver, true)
        );
        emit NameListed(ensNameLabel, nameNode, msg.sender);
    }

    function unlist(string memory ensNameLabel) external {
        bytes32 nameNode = _node(ETH_NODE, ensNameLabel);

        _isNameOwner(nameNode);

        if (!registry.get(nameNode).isListed) {
            revert LabelListingNotFound(ensNameLabel);
        }

        registry.remove(nameNode);
        emit NameUnlisted(ensNameLabel, nameNode, msg.sender);
    }

    function _isNameOwner(bytes32 node) internal view {
        address nameOwner = INameWrapper(nameWrapper).ownerOf(uint256(node));

        if (nameOwner != msg.sender) {
            revert NotNameOwner(msg.sender, nameOwner);
        }
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

        ListedENSName memory listing = registry.get(context.parentNode);
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

    // curently, all the info required for minting is calculated offchain and send via parameters with sigature
    // maybe we can store listing prices on chain and use offchain for additional minting condition (whitelistings, reservations, tokenGated)
    function _mint(MintSubnameContext memory context) internal {
        INameWrapper(nameWrapper).setSubnodeRecord(
            context.parentNode,
            context.subnameLabel,
            context.subnameOwner,
            context.resolver,
            type(uint64).max,
            context.fuses,
            type(uint64).max
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
        emit SubnameMinted(
            context.parentNode,
            context.subnameLabel,
            context.mintPrice,
            paymentReceiver,
            msg.sender,
            context.subnameOwner
        );
    }

    function _node(
        bytes32 parent,
        string memory label
    ) internal pure returns (bytes32) {
        bytes32 labelhash = keccak256(bytes(label));
        return keccak256(abi.encodePacked(parent, labelhash));
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
