// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IExtendedResolver} from "./IExtendedResolver.sol";
import {SupportsInterface} from "./SupportsInterface.sol";
import {SignatureVerifier} from "./SignatureVerifier.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IResolverService {
    function resolve(
        bytes calldata name,
        bytes calldata data
    )
        external
        view
        returns (bytes memory result, uint64 expires, bytes memory sig);
}

/**
 * Implements an ENS resolver that directs all queries to a CCIP read gateway.
 * Callers must implement EIP 3668 and ENSIP 10.
 */

contract OffchainResolver is Ownable, IExtendedResolver, SupportsInterface {
    string[] public urls;
    mapping(address => bool) public signers;
    uint private constant REMOVE_SIGNERS = 0;
    uint private constant ADD_SIGNERS = 1;
    event NewSigners(address[] signers);
    event SignersRemoved(address[] signers);

    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    constructor(
        string[] memory _urls,
        address[] memory _signers,
        address _contractOwner
    ) Ownable(_contractOwner) {
        urls = _urls;
        for (uint i = 0; i < _signers.length; i++) {
            signers[_signers[i]] = true;
        }
        emit NewSigners(_signers);
    }

    /**
     * Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function resolve(
        bytes calldata name,
        bytes calldata data
    ) external view override returns (bytes memory) {
        bytes memory callData = abi.encodeWithSelector(
            IResolverService.resolve.selector,
            name,
            data
        );

        revert OffchainLookup(
            address(this),
            urls,
            callData,
            OffchainResolver.resolveWithProof.selector,
            abi.encode(callData, address(this))
        );
    }

    /**
     * Callback used by CCIP read compatible clients to verify and parse the response.
     */
    function resolveWithProof(
        bytes calldata response,
        bytes calldata extraData
    ) external view returns (bytes memory) {
        (address signer, bytes memory result) = SignatureVerifier.verify(
            extraData,
            response
        );

        require(signers[signer], "Signature: Invalid signature");

        return result;
    }

    function supportsInterface(
        bytes4 interfaceID
    ) public pure override returns (bool) {
        return
            interfaceID == type(IExtendedResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function setUrl(string[] memory _urls) external onlyOwner {
        urls = _urls;
    }

    function setSigners(
        address[] calldata _signers,
        uint operation
    ) external onlyOwner {
        require(
            _signers.length > 0 &&
                (operation == REMOVE_SIGNERS || operation == ADD_SIGNERS),
            "Invalid operation"
        );

        if (operation == REMOVE_SIGNERS) {
            for (uint i = 0; i < _signers.length; i++) {
                delete signers[_signers[i]];
            }
            emit SignersRemoved(_signers);
        } else if (operation == ADD_SIGNERS) {
            for (uint i = 0; i < _signers.length; i++) {
                signers[_signers[i]] = true;
            }
            emit NewSigners(_signers);
        }
    }
}
