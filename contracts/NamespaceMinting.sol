//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import {MintSubnameContext, ListedENSName } from "./Types.sol";
import {Controllable} from "./controllers/Controllable.sol";
import {INamespaceRegistry} from "./INamespaceRegistry.sol";
import {INameWrapper} from "./ens/INameWrapper.sol";
import {IPublicResolver} from "./ens/IPublicResolver.sol";
import {INameWrapperProxy} from "./INameWrapperProxy.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

error NameNotListed(bytes32 node);
error NotEnoughFunds(uint256 current, uint256 expected);

contract NamespaceMinter is Controllable, EIP712, ERC1155Holder {
    event SubnameMinted(
        bytes32 indexed parentNode,
        string label,
        uint256 mintPrice,
        uint256 mintFee,
        address indexed paymentReceiver,
        address sender,
        address subnameOwner
    );

    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address resolver,address subnameOwner,uint32 fuses,uint256 mintPrice,uint256 mintFee,uint64 expiry)"
        );

    address private verifier;
    address private treasury;
    INamespaceRegistry registry;
    INameWrapperProxy wrapperProxy;
    INameWrapper nameWrapper;

    mapping(bytes32 => bool) signatures;

    constructor(
        address _treasury,
        address _verifier,
        address _nameWrapperProxy,
        address _nameWrapper,
        address _namespaceRegistry,
        string memory version
    ) EIP712("namespace", version) {
        treasury = _treasury;
        verifier = _verifier;
        nameWrapper = INameWrapper(_nameWrapper);
        wrapperProxy = INameWrapperProxy(_nameWrapperProxy);
        registry = INamespaceRegistry(_namespaceRegistry);
    }

    function mint(
        MintSubnameContext memory context,
        bytes memory signature
    ) external payable {
        ListedENSName memory listing = _getListing(context.parentNode);

        _verifySignature(context, signature);

        wrapperProxy.setSubnodeRecord(
            context.parentNode,
            context.subnameLabel,
            context.subnameOwner,
            context.resolver,
            context.ttl,
            context.fuses,
            context.expiry
        );

        _transferFunds(
            listing.paymentReceiver,
            context.mintPrice,
            context.mintFee
        );

        emit SubnameMinted(
            context.parentNode,
            context.subnameLabel,
            context.mintPrice,
            context.mintFee,
            listing.paymentReceiver,
            msg.sender,
            context.subnameOwner
        );
    }

    function mintWithData(
        MintSubnameContext calldata context,
        bytes calldata signature,
        bytes[] calldata data
    ) external payable {
        
        if (data.length == 0) {
            this.mint(context,signature);
            return;
        }
    
        require(
            context.resolver != address(0),
            "Resolver address must be set when updating records"
        );

        ListedENSName memory listing = _getListing(context.parentNode);

        _verifySignature(context, signature);

        bytes32 subnameNode = wrapperProxy.setSubnodeRecord(
            context.parentNode,
            context.subnameLabel,
            address(this),
            context.resolver,
            context.ttl,
            context.fuses,
            context.expiry
        );

        _setRecords(context.resolver, subnameNode, data);

        nameWrapper.safeTransferFrom(
            address(this),
            context.subnameOwner,
            uint256(subnameNode),
            1,
            bytes("")
        );

        _transferFunds(
            listing.paymentReceiver,
            context.mintPrice,
            context.mintFee
        );

        emit SubnameMinted(
            context.parentNode,
            context.subnameLabel,
            context.mintPrice,
            context.mintFee,
            listing.paymentReceiver,
            msg.sender,
            context.subnameOwner
        );
    }

    function _getListing(
        bytes32 nameNode
    ) internal view returns (ListedENSName memory) {
        ListedENSName memory listing = registry.get(nameNode);
        if (!listing.isListed) {
            revert NameNotListed(nameNode);
        }
        return listing;
    }

    function _transferFunds(
        address paymentReceiver,
        uint256 mintPrice,
        uint256 mintFee
    ) internal {
        require(msg.value >= mintFee + mintPrice, "Insufficient funds");

        payable(paymentReceiver).transfer(mintPrice);
        payable(treasury).transfer(mintFee);
    }

    function setTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function withdraw() external onlyOwner() {
        require(address(this).balance > 0, "No funds present.");
        payable(treasury).transfer(address(this).balance);
    }

    function _verifySignature(
        MintSubnameContext memory context,
        bytes memory signature
    ) internal {
        bytes32 signatureHash = keccak256(signature);
        require(!signatures[signatureHash], "Signature already used");

        require(
            _extractSigner(context, signature) == verifier,
            "Invalid signature"
        );

        signatures[signatureHash] = true;
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
                    context.mintFee,
                    context.expiry
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }

    function _setRecords(
        address resolverAddress,
        bytes32 subnameNode,
        bytes[] calldata data
    ) internal {
        IPublicResolver resolver = IPublicResolver(resolverAddress);
        resolver.multicallWithNodeCheck(subnameNode, data);
    }

    function setVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function setNameWrapper(address _nameWrapper) external onlyOwner {
        nameWrapper = INameWrapper(_nameWrapper);
    }
}
