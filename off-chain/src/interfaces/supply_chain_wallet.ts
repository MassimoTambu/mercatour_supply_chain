import { FromSeed } from "@lucid-evolution/lucid";

export type SupplyChainWallet = FromSeed & {
  seedPhrase: string; verificationKey: string; verificationKeyHash: string;
};
