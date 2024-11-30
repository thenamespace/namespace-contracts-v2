// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
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


abstract contract OffchainResolver is Ownable {
    mapping(address => bool) private signers;
    event SignerChanged(address signer, bool removed);
    event OffchainUrlsChanged(string[] urls);

    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    constructor(address[] memory _signers) {
        modifyOffchainSigners(_signers, false);
    }

    /**
     * Resolves a name, as specified by ENSIP 10.
     * @param name The DNS-encoded name to resolve.
     * @param data The ABI encoded data for the underlying resolution function (Eg, addr(bytes32), text(bytes32,string), etc).
     * @return The return data, ABI encoded identically to the underlying function.
     */
    function _resolveOffchain(
        bytes memory name,
        bytes memory data,
        string[] memory urls
    ) internal view returns (bytes memory) {
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
        (address signer, bytes memory result) = verify(
            extraData,
            response
        );

        require(signers[signer], "Signature: Invalid signature");

        return result;
    }

    /**
     * @dev Generates a hash for signing/verifying.
     * @param target: The address the signature is for.
     * @param request: The original request that was sent.
     * @param result: The `result` field of the response (not including the signature part).
     */
    function makeSignatureHash(
        address target,
        uint64 expires,
        bytes memory request,
        bytes memory result
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    hex"1900",
                    target,
                    expires,
                    keccak256(request),
                    keccak256(result)
                )
            );
    }

    /**
     * @dev Verifies a signed message returned from a callback.
     * @param request: The original request that was sent.
     * @param response: An ABI encoded tuple of `(bytes result, uint64 expires, bytes sig)`, where `result` is the data to return
     *        to the caller, and `sig` is the (r,s,v) encoded message signature.
     * @return signer: The address that signed this message.
     * @return result: The `result` decoded from `response`.
     */
    function verify(
        bytes calldata request,
        bytes calldata response
    ) internal view returns (address, bytes memory) {
        (bytes memory result, uint64 expires, bytes memory sig) = abi.decode(
            response,
            (bytes, uint64, bytes)
        );
        (bytes memory extraData, address sender) = abi.decode(
            request,
            (bytes, address)
        );
        address signer = ECDSA.recover(
            makeSignatureHash(sender, expires, extraData, result),
            sig
        );
        require(
            expires >= block.timestamp,
            "SignatureVerifier: Signature expired"
        );
        return (signer, result);
    }

    function modifyOffchainSigners(
        address[] memory _signers,
        bool remove
    ) public onlyOwner {
        for (uint i = 0; i < _signers.length; i++) {
            if (remove) {
                signers[_signers[i]] = false;
                emit SignerChanged(_signers[i], true);
            } else {
                signers[_signers[i]] = true;
                emit SignerChanged(_signers[i], false);
            }
        }
    }
}
