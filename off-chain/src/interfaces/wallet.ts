import { Address, PrivateKey, PublicKey } from "@emurgo/cardano-serialization-lib-nodejs";

export interface SupplyChainWallet {
  paymentAddress: Address;
  signingKey: PrivateKey;
  verificationKey: PublicKey;
}
