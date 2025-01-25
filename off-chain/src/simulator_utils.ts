import * as Cardano from '@emurgo/cardano-serialization-lib-nodejs';
import { SupplyChainWallet } from './interfaces/wallet.ts';

export class SU {
  static getEnvVar(name: string): string {
    const envVar = Deno.env.get(name);
    if (envVar === undefined) {
      throw new Error(`${name} is not defined`);
    }
    return envVar;
  }

  static getFundWallet(): SupplyChainWallet {
    const fundAddress = SU.getEnvVar("FUND_ADDRESS");
    const fundSigningKey = SU.getEnvVar("FUND_SIGNING_KEY");
    const fundVerificationKey = SU.getEnvVar("FUND_VERIFICATION_KEY");

    return {
      paymentAddress: Cardano.Address.from_bech32(fundAddress),
      signingKey: Cardano.PrivateKey.from_bech32(fundSigningKey),
      verificationKey: Cardano.PublicKey.from_bech32(fundVerificationKey),
    };
  }

  static createWallet(): SupplyChainWallet {
    // Generate a private key (Ed25519)
    const signingKey = Cardano.PrivateKey.generate_ed25519();

    // Derive the public key from the private key
    const verificationKey = signingKey.to_public();

    const baseAddress = Cardano.BaseAddress.new(
      Cardano.NetworkInfo.testnet_preview().network_id(),
      Cardano.Credential.from_keyhash(verificationKey.hash()),
      Cardano.Credential.from_keyhash(verificationKey.hash())
    );

    return {
      paymentAddress: baseAddress.to_address(),
      signingKey: signingKey,
      verificationKey: verificationKey
    };
  }

  // createNFTCertificate(wallet: SupplyChainWallet, policyId: string, assetName: string): Cardano.Certificate {


  //   const mint = Cardano.MintAssets.(Buffer.from(policyId, 'hex'), Buffer.from(assetName, 'utf8'));
  //   return Cardano.Certificate.new_stake_credential_registration(wallet.verificationKey.hash(), mint);
  // }
}
