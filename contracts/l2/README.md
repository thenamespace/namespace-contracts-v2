# Contract Overview: L2 ENS Subname minting 

High-level contract overview for implementing ENS Subname minting on different L2 chains (Base, Optimims, etc.).


## NamespaceMintController 

[0x5C1220C4C5D75aC2d0A2f893995b5eCec98F3Aa6](https://optimistic.etherscan.io/address/0x5C1220C4C5D75aC2d0A2f893995b5eCec98F3Aa6)

Central authority for managing subname operations under deployed registries. 

Responsible for:

- **Minting Subnames**: Creates new subnames within specific registries, ensuring all required conditions are met.
- **Registry Deployment**: Oversees the deployment of new mint registries, allowing custom namespaces.
- **Expiry Management**: Provides functionality to extend the expiration of existing subnames.

## NamePublicResolver** 

[0xD8de4F5D7117BA37bA171ec9180Da798056f2CEd](https://optimistic.etherscan.io/address/0xd8de4f5d7117ba37ba171ec9180da798056f2ced)

A streamlined adaptation of the ENS Public Resolver contract designed to handle name record management efficiently on Optimism. 

Responsible for:
- **Record Storage**: Maintains mappings for subnames, such as addresses, content hashes, or other key data.

## NodeResolver 

[0xD8de4F5D7117BA37bA171ec9180Da798056f2CEd](https://optimistic.etherscan.io/address/0xd8de4f5d7117ba37ba171ec9180da798056f2ced)

A specialized contract for resolving the corresponding ERC721 registry for any given name or subname. 

Responsible for:

- **Registry Mapping**: Identify and link names to their respective ERC721 contracts.
- **Subname Navigation**: Enable seamless lookups for subnames within the system.

## Emitter 

[0x87516b5518a6548433ab97ae59b15b1a31472f11](https://optimistic.etherscan.io/address/0x87516b5518a6548433ab97ae59b15b1a31472f11)

This contract provides a unified mechanism for logging events across all deployed registries. 

Responsible for:

- Standardize Event Emission: Ensure all registries follow a consistent format for emitting events, simplifying tracking and monitoring.
- Support Interoperability: Facilitate integration with external tools and systems by providing a common event structure.

## ENSNameRegistry

An ERC721-compliant registry contract designed to store subnames as NFTs. This ensures secure and transparent ownership. Key aspects include:

- Subname as NFTs: Each subname is represented as an NFT, inheriting the benefits of blockchain-based ownership, including transferability and immutability.
- Compatibility: Fully supports ERC721 standards, allowing seamless integration with wallets, marketplaces, and other blockchain tools.

## Hybrid Resolver

Specialized resolver contract that ENS names use to set up for their subnames to be resolvable on the L2 chain
while keeping the parent ENS name records on L1 (with options to migrate all records on the L2 chain).

[Hybrid Resolver Repo](https://github.com/thenamespace/namespace-contracts-v2/tree/main/contracts/hybrid-resolver).

---

## Features

- Minting L2 Subnames
- CCIP-read resolution
- Supported L2s (Base, Optimism, Base Sepolia)

## Documentation

If you're interested in learning more about ENS Subname registrations, and more features, you can check our official [documentation](https://docs.namespace.tech/dev-docs/overview).
- [How to implement Subname minting in your Dapp in 20 minutes](https://docs.namespace.tech/dev-docs/how-to-guides/mint-l1-or-l2-subnames-using-sdk).
- [How does L2 subname minting work?](https://docs.namespace.tech/dev-docs/namespace-l2-subnames)
- [Namespace SDK](https://docs.namespace.tech/dev-docs/namespace-sdk) for streamlining Subname registration implementation.


## License

[MIT](https://choosealicense.com/licenses/mit/)

## Demo

Check out a demo on [How to list an ENS Name and start issuing Subnames](https://www.loom.com/share/942c600163a5447f890ed9c9ca332db5?sid=8f0d1b8f-b15b-449e-a409-1d841aa9c21b).


## Authors

- [@nenadmitt](https://github.com/nenadmitt)
- [@thecaphimself](https://github.com/thecaphimself)

---

![Logo](https://i.ibb.co/WBzB7LQ/pic-png-white.png)

