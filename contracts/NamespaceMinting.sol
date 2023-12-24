//SPDX-License-Identifier: UNLICENSED
pragma solidity ~0.8.20;

import "./Types.sol";
import "./controllers/Controllable.sol";
import "./INamespaceRegistry.sol";
import "./NameWrapperDelegate.sol";
import "./ens/INameWrapper.sol";

error NameNotListed(bytes32 node);
error NotEnoughFunds(uint256 current, uint256 expected);

contract NamespaceMinting is Controllable {
    event SubnameMinted(
        bytes32 indexed parentNode,
        string label,
        uint256 price,
        address indexed paymentReceiver,
        address sender,
        address subnameOwner
    );

    address private treasury;
    address public nameWrapperDelegate;
    INamespaceRegistry registry;

    constructor(
        address _treasury,
        address _controller,
        address _nameWrapperDelegate,
        address _registry
    ) Controllable(msg.sender, _controller) {
        treasury = _treasury;
        nameWrapperDelegate = _nameWrapperDelegate;
        registry = INamespaceRegistry(_registry);
    }

    // @context
    // @param
    function mint(
        MintSubnameContext memory context,
        bytes memory signature
    ) external payable {
        ListedENSName memory listing = registry.get(context.parentNode);
        if (!listing.isListed) {
            revert NameNotListed(context.parentNode);
        }

        uint256 totalPrice = context.mintFee + context.mintPrice;
        if (msg.value < totalPrice) {
            revert NotEnoughFunds(msg.value, totalPrice);
        }

        _mint(context, signature);
        _transferFunds(
            listing.paymentReceiver,
            context.mintPrice,
            context.mintFee
        );
        _emit(context, listing.paymentReceiver);
    }

    // curently, all the info required for minting is calculated offchain and send via parameters with sigature
    // maybe we can store listing prices on chain and use offchain for additional minting condition (whitelistings, reservations, tokenGated)
    function _mint(
        MintSubnameContext memory context,
        bytes memory signature
    ) internal {
        NameWrapperDelegate(nameWrapperDelegate).setSubnodeRecord(
            context,
            signature,
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

    function setTreasury(address _treasury) external onlyController {
        treasury = _treasury;
    }

    function withdraw() external onlyController {
        require(address(this).balance > 0, "No funds present.");
        payable(treasury).transfer(address(this).balance);
    }
}
