// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SignatureVerifier} from "./SignatureVerifier.sol";
import {INodeRegistryResolver} from "../registry-resolver/INodeRegistryResolver.sol";
import {IRegistryEmitter} from "../registries/IRegistryEmitter.sol";
import {IEnsNameRegistry} from "../registries/IEnsNameRegistry.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";
import {IRegistryControllerProxy} from "./RegistryControllerProxy.sol";
import {IMulticallable} from "../resolver/IMulticallable.sol";

abstract contract ControllerBase is Ownable, SignatureVerifier {
    INodeRegistryResolver registryResolver;
    IRegistryEmitter emitter;
    IRegistryControllerProxy controllerProxy;
    address public treasury;
    address public resolver;
    address public tokenMetadata;

    constructor(
        address _verifier,
        address _treasury,
        address _tokenMetadata,
        address _registryResolver,
        address _emitter,
        address _resolver,
        address _controllerProxy
    ) Ownable(_msgSender()) SignatureVerifier(_verifier) {
        tokenMetadata = _tokenMetadata;
        registryResolver = INodeRegistryResolver(_registryResolver);
        emitter = IRegistryEmitter(_emitter);
        controllerProxy = IRegistryControllerProxy(_controllerProxy);
        treasury = _treasury;
        resolver = _resolver;
    }


    function setTreasury(address _treasury) public onlyOwner {
        treasury = _treasury;
    }

    function setResolver(address _resolver) public onlyOwner {
        resolver = _resolver;
    }

    function setResolverData(bytes[] memory resolverData) internal {
        IMulticallable(resolver).multicall(resolverData);
    }

    function setVerifier(address _verifier, bool allowed) public onlyOwner {
        _setVerifier(_verifier, allowed);
    }

    function transferFunds(uint256 price, uint256 fees, address paymentReceiver) internal {
        uint256 totalPrice = price + fees;
        require(msg.value >= totalPrice, "Insufficient balance");

         if (price > 0) {
            (bool sentToPaymentReceiver, ) = payable(paymentReceiver).call{
                value: price
            }("");
            require(sentToPaymentReceiver, "Could not transfer ETH to payment receiver");
        }

        if (fees > 0) {
            (bool sentToTreasury, ) = payable(treasury).call{
                value: fees
            }("");
            require(sentToTreasury, "Could not transfer ETH to treasury");
        }

        uint256 remainder = msg.value - totalPrice;
        if (remainder > 0) {
            (bool remainderSent, ) = payable(msg.sender).call{value: remainder}(
                ""
            );
            require(remainderSent, "Could not transfer ETH to msg.sender");
        }
    }
}
