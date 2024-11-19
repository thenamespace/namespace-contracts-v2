<img src="" width="40px"/>

# Namespace Contracts

This repository contains smart contracts designed for listing and minting subnames on both Layer 1 (L1) and Layer 2 (L2) Ethereum chains. Built using Hardhat and Solidity.

Namespace allows ENS name owners to "list" a name and allow others to mint subnames under a listed name.

We have lots of different configurations for listed name such as:
1. Setting custom prices per label length
2. Setting custom prices per label type ( numbers only, emoji only )
3. Subname reservations. Lister can disallow registration of a certail label or it can set a special price for it.
4. Whitelisting.
5. Token gated access ( ERC721/ERC1155/ERC20 )
6. And many more to come

Because of that, listing/minting logic is offloaded to an offchain server
 
---

### Features

## Listing and Minting ENS Subnames on Layer two chains, powered by ENSIP-10

### 1. NameRegistryController

A registry controller contract responsible for minting subnames, deploying registrie  and extending the expiry of existing registries. It verifies off-chain signatures before performing these actions using an EIP712

### 2. NamePublicResolver

Public resolver is a replica of ENS Public Resolver contract and is used to store records for all the subnames on an L2 chain

### 3. RegistryResolver

Resolver contract used to map subnames to their registry address

### 4. EnsRegistry

Every listed name is deployed as an ERC721 contract.

### 5. RegistryEmitter

Contracts used by an EnsRegistries to emit common events, such as Mints, Transfers, Burns, Expiries

## Listing and Minting ENS Subnames on Ethereum Mainnet

### 1. NamespaceMinter

Smart contract responsible for minting subnames by calling the ENS NameWrapper contract.

Uses EIP712 for signature verification

### 2. NamespaceLister

Responsible for storing the information about the listed names.


---

