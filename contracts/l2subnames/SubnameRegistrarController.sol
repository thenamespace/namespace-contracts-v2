//SPDX-License-Identifier: MIT
pragma solidity ~0.8.20;

import {Controllable} from "../controllers/Controllable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {MintL2SubnameContext} from "./Types.sol";
import {ISubnameRegistar} from "./SubnameRegistar.sol";

contract SubnameRegistarController is Controllable, EIP712 {
    address private verifier;
    address public treasury;
    ISubnameRegistar public registar;

    event SubnameMinted(
        string label,
        bytes32 parentNode,
        address resolver,
        address owner
    );

    bytes32 constant MINT_CONTEXT =
        keccak256(
            "MintContext(string subnameLabel,bytes32 parentNode,address paymentReceiver,address resolver,address subnameOwner,uint256 mintPrice,uint256 mintFee,uint64 expiry)"
        );

    constructor(
        address _verifier,
        address _treasury,
        address _registar,
        string memory version
    ) EIP712("namespace", version) Controllable(msg.sender) {
        verifier = _verifier;
        treasury = _treasury;
        registar = ISubnameRegistar(_registar);
    }

    function mintSubname(
        MintL2SubnameContext memory context,
        bytes memory signature,
        bytes[] memory resolverData
    ) external payable {
        require(
            _extractSigner(context, signature) == verifier,
            "Invalid signature"
        );

        uint256 totalPrice = context.mintFee + context.mintPrice;

        require(totalPrice >= msg.value, "Not enough funds");

        bytes32 nameNode = _namehash(context.subnameLabel, context.parentNode);

        registar.mintSubname(nameNode, context.subnameOwner, context.expiry);
        _transferFunds(context);

        emit SubnameMinted(
            context.subnameLabel,
            context.parentNode,
            context.resolver,
            context.subnameOwner
        );
    }

    function _transferFunds(MintL2SubnameContext memory context) internal {
        bool sentToOwner = payable(context.paymentReceiver).call{
            value: context.mintPrice
        }("");
        bool sentToTreasury = payable(treasury).call{value: context.mintFee}(
            ""
        );
        require(sentToOwner && sentToTreasury, "Could not transfer ETH");
    }

    function _extractSigner(
        MintL2SubnameContext memory context,
        bytes memory signature
    ) internal view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    MINT_CONTEXT,
                    keccak256(abi.encodePacked(context.subnameLabel)),
                    context.parentNode,
                    context.paymentReceiver,
                    context.resolver,
                    context.subnameOwner,
                    context.mintPrice,
                    context.mintFee,
                    context.expiry
                )
            )
        );
        return ECDSA.recover(digest, signature);
    }

    function _namehash(
        bytes32 parentNode,
        string memory nameLabel
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(parentNode, _labelhash(nameLabel)));
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function setVerifier(address _verifier) external onlyOwner {
        verifier = _verifier;
    }

    function transfer(address receiver, uint256 amount) onlyOwner {
        require(address(this).balance >= amount, "Not enough funds");
    }
}
