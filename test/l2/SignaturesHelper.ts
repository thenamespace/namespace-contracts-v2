import { Account, Address, Hash } from "viem";

const MintContextTypes = {
  MintContext: [
    { name: "label", type: "string" },
    { name: "parentNode", type: "bytes32" },
    { name: "owner", type: "address" },
    { name: "price", type: "uint256" },
    { name: "fee", type: "uint256" },
    { name: "paymentReceiver", type: "address" },
    { name: "expiry", type: "uint256" },
    { name: "nonce", type: "uint256" },
  ],
};

const FactoryContextTypes = {
  FactoryContext: [
    { name: "tokenName", type: "string" },
    { name: "tokenSymbol", type: "string" },
    { name: "label", type: "string" },
    { name: "TLD", type: "string" },
    { name: "owner", type: "address" },
    { name: "parentControl", type: "uint8" },
    { name: "expirableType", type: "uint8" },
  ],
};

const ExtendExpiryTypes = {
  ExtendExpiryContext: [
    { name: "node", type: "bytes32" },
    { name: "expiry", type: "uint256" },
    { name: "price", type: "uint256" },
    { name: "fee", type: "uint256" },
    { name: "paymentReceiver", type: "address" },
    { name: "nonce", type: "uint256" },
  ],
};

export interface MintContext {
  owner: Address;
  label: string;
  parentNode: Hash;
  price: bigint;
  fee: bigint;
  paymentReceiver: Address;
  expiry: bigint;
  nonce: bigint
}

export interface FactoryContext {
  tokenName: string;
  tokenSymbol: string;
  label: string;
  TLD: string;
  owner: Address;
  parentControl: number;
  expirableType: number;
}

export interface ExtendExpiryContext {
  node: Hash;
  expiry: bigint;
  price: bigint;
  fee: bigint;
  paymentReceiver: Address;
  nonce: bigint
}

export const generateMintContextSignature = async (
  context: MintContext,
  wallet: Account,
  chainId: number,
  contractAddress: Address
) => {
  const Domain = {
    name: "namespace",
    version: "1",
    chainId: chainId,
    verifyingContract: contractAddress,
  };

  const message = {
    label: context.label,
    parentNode: context.parentNode,
    owner: context.owner,
    price: context.price,
    fee: context.fee,
    paymentReceiver: context.paymentReceiver,
    expiry: context.expiry,
    nonce: context.nonce
  };

  //@ts-ignore
  return await wallet.signTypedData({
    domain: Domain,
    message: message,
    types: MintContextTypes,
    primaryType: "MintContext",
  });
};

export const generateExtendExpiryContextSignature = async (
  context: ExtendExpiryContext,
  wallet: Account,
  chainId: number,
  contractAddress: Address
) => {
  const Domain = {
    name: "namespace",
    version: "1",
    chainId: chainId,
    verifyingContract: contractAddress,
  };

  const message = {
    node: context.node,
    expiry: context.expiry,
    price: context.price,
    fee: context.fee,
    paymentReceiver: context.paymentReceiver,
    nonce: context.nonce
  };

  //@ts-ignore
  return await wallet.signTypedData({
    domain: Domain,
    message: message,
    types: ExtendExpiryTypes,
    primaryType: "ExtendExpiryContext",
  });
};

export const generateFactoryContextSignature = async (
  context: FactoryContext,
  wallet: Account,
  chainId: number,
  contractAddress: Address
) => {
  const Domain = {
    name: "namespace",
    version: "1",
    chainId: chainId,
    verifyingContract: contractAddress,
  };

  const message = {
    tokenName: context.tokenName,
    tokenSymbol: context.tokenSymbol,
    label: context.label,
    TLD: context.TLD,
    owner: context.owner,
    parentControl: context.parentControl,
    expirableType: context.expirableType,
  };

  //@ts-ignore
  return await wallet.signTypedData({
    domain: Domain,
    message: message,
    types: FactoryContextTypes,
    primaryType: "FactoryContext",
  });
};


export const randomNonce = () => {
  const randomNumber = Math.floor(Math.random() * 10000000000000);
  return BigInt(randomNumber);
}