import * as Cardano from '@emurgo/cardano-serialization-lib-nodejs';
import { SupplyChainWallet } from './interfaces/wallet.ts';
import { LucidEvolution } from "@lucid-evolution/lucid";
import { fromText } from '@lucid-evolution/core-utils';
import { RedeemerBuilder, Script } from '@lucid-evolution/core-types';
import { Data } from '@lucid-evolution/plutus';
import { ConvertedBlueprint } from "./interfaces/converted_blueprint.ts";

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

  static async createUserNFTCertificate(lucid: LucidEvolution): Promise<void> {
    const fundAddress = SU.getEnvVar("FUND_ADDRESS");
    const signerKey = SU.getEnvVar("FUND_SIGNING_KEY");
    const policyId = Deno.readTextFileSync('generated/user_nfts_policy_id').trim();
    const tokenName = SU.getEnvVar("USER_NFT_CERTIFICATE_NAME");
    const validatorBlueprint = JSON.parse(Deno.readTextFileSync('generated/user_nfts_mint_validator_params.json')) as ConvertedBlueprint;
    const mintingPolicy: Script = { type: "PlutusV3", script: validatorBlueprint.cborHex };
    const redeemer: RedeemerBuilder = { kind: "self", makeRedeemer: (_) => Data.void() };

    const unit = policyId + fromText(tokenName);
    const date = new Date();
    date.setHours(date.getHours() + 1);

    lucid.selectWallet.fromPrivateKey(signerKey);

    const tx = await lucid.newTx()
      .mintAssets({ [unit]: 1n }, redeemer)
      .pay.ToAddress(fundAddress, { [unit]: 1n })
      .validTo(date.getTime())
      .attach.MintingPolicy(mintingPolicy)
      .complete();

    // const signedTx = await tx.sign.withPrivateKey(signerKey).complete();
    // const txHash = await signedTx.submit();
    // console.log(`User NFT Certificate minted with tx hash: ${txHash}`);
  }
}
