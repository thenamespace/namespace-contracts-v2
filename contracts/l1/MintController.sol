// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MintContext, MINT_CONTEXT} from "./Types.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Controllable} from "../controllers/Controllable.sol";
import {IMulticallable} from "@ensdomains/ens-contracts/contracts/resolvers/Multicallable.sol";
import {INameWrapper, CANNOT_UNWRAP} from "../ens/INameWrapper.sol";

contract MintController is Controllable, EIP712, ERC1155Holder {
    mapping(address => bool) private verifiers;
    mapping(bytes32 => bool) private fuseBurned;
    address private treasury;
    address private wrapperProxy;
    address private nameWrapper;
    address private publicResolver;
    uint64 private TTL = 0;

    event SubnameMinted(
        bytes32 parentNode,
        string label,
        uint256 price,
        uint256 fee,
        address paymentReceiver,
        address owner,
        bytes extraData
    );

    constructor(
        address _verifier,
        address _treasury,
        address _wrapperProxy,
        address _nameWrapper,
        address _publicResolver
    ) EIP712("namespace", "1") {
        verifiers[_verifier] = true;
        treasury = _treasury;
        wrapperProxy = _wrapperProxy;
        nameWrapper = _nameWrapper;
        publicResolver = _publicResolver;
    }

    function mint(
        MintContext calldata ctx,
        bytes calldata sig,
        bytes[] calldata resolverData,
        bytes calldata extraData
    ) public payable {
        verifySignature(ctx, sig);
        ensureCannotUnwrapFuseBurned(ctx.parentNode);

        if (resolverData.length > 0) {
            mintWithData(ctx, resolverData);
        } else {
            mintSimple(ctx);
        }

        transferFunds(ctx.paymentReceiver, ctx.price, ctx.fee);

        emit SubnameMinted(
            ctx.parentNode,
            ctx.label,
            ctx.price,
            ctx.fee,
            ctx.paymentReceiver,
            ctx.owner,
            extraData
        );
    }

    function mintWithData(
        MintContext calldata context,
        bytes[] calldata resolverData
    ) internal {
        bytes32 subnameNode = INameWrapper(wrapperProxy).setSubnodeRecord(
            context.parentNode,
            context.label,
            address(this),
            publicResolver,
            TTL,
            context.fuses,
            context.expiry
        );

        _setRecords(publicResolver, subnameNode, resolverData);

        INameWrapper(nameWrapper).safeTransferFrom(
            address(this),
            context.owner,
            uint256(subnameNode),
            1,
            bytes("")
        );
    }

    function mintSimple(MintContext calldata context) internal {
        INameWrapper(wrapperProxy).setSubnodeRecord(
            context.parentNode,
            context.label,
            context.owner,
            publicResolver,
            TTL,
            context.fuses,
            context.expiry
        );
    }

    function verifySignature(
        MintContext calldata context,
        bytes calldata signature
    ) internal view {
        require(context.signatureExpiry > block.timestamp, "Signature expired");

        require(context.verifiedMinter == msg.sender, "Not verified minter");

        bytes32 signatureDigest = _createSignatureDigest(context);
        address extractedSigner = ECDSA.recover(signatureDigest, signature);

        require(verifiers[extractedSigner], "Invalid signature");
    }

    function transferFunds(
        address paymentReceiver,
        uint256 price,
        uint256 fees
    ) internal {
        uint256 totalPrice = price + fees;
        uint256 ethAmmount = msg.value;
        require(ethAmmount >= totalPrice, "Insufficient balance");

        if (price > 0) {
            (bool sentToPaymentReceiver, ) = payable(paymentReceiver).call{
                value: price
            }("");
            require(
                sentToPaymentReceiver,
                "Could not transfer ETH to payment receiver"
            );
        }

        if (fees > 0) {
            (bool sentToTreasury, ) = payable(treasury).call{value: fees}("");
            require(sentToTreasury, "Could not transfer ETH to treasury");
        }

        uint256 remainder = ethAmmount - totalPrice;
        if (remainder > 0) {
            (bool remainderSent, ) = payable(msg.sender).call{value: remainder}(
                ""
            );
            require(remainderSent, "Could not transfer ETH to msg.sender");
        }
    }

    function _createSignatureDigest(
        MintContext calldata context
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
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
                        context.verifiedMinter,
                        context.fuses
                    )
                )
            );
    }

    function ensureCannotUnwrapFuseBurned(bytes32 name) internal {
        if (fuseBurned[name]) {
            return;
        }

        if (!INameWrapper(nameWrapper).allFusesBurned(name, CANNOT_UNWRAP)) {
            INameWrapper(wrapperProxy).setFuses(name, uint16(CANNOT_UNWRAP));
        }

        fuseBurned[name] = true;
    }

    function _setRecords(
        address resolverAddress,
        bytes32 subnameNode,
        bytes[] calldata data
    ) internal {
        IMulticallable(resolverAddress).multicallWithNodeCheck(
            subnameNode,
            data
        );
    }

    function setVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = true;
    }

    function removeVerifier(address verifier) external onlyOwner {
        verifiers[verifier] = false;
    }

    function setDefaultResolver(address resolver) external onlyOwner {
        publicResolver = resolver;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
