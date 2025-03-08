import { SupplyChainWallet } from './interfaces/supply_chain_wallet.ts';
import { LucidEvolution, walletFromSeed } from '@lucid-evolution/lucid';
import { fromText } from '@lucid-evolution/core-utils';
import { Constr, Data } from '@lucid-evolution/plutus';
import { Address, Assets, AddressDetails, MintingPolicy, SpendingValidator } from "@lucid-evolution/core-types";
import { applyDoubleCborEncoding, generateSeedPhrase, getAddressDetails, mintingPolicyToId, toPublicKey, toUnit, validatorToAddress } from "@lucid-evolution/utils";
import { PlutusJson } from "./interfaces/plutus_json.ts";
import * as Cardano from "@emurgo/cardano-serialization-lib-nodejs";
import plutusJson from "../../../on-chain/plutus.json" with { type: "json" };
import productsJson from "../products.json" with { type: "json" };
import { Buffer } from "node:buffer";
import { ProductMetadata } from "./interfaces/product_metadata.ts";

export class SU {
  static getEnvVar(name: string): string {
    const envVar = Deno.env.get(name);
    if (envVar === undefined) {
      throw new Error(`${name} is not defined`);
    }
    return envVar;
  }

  static generateWallet(): SupplyChainWallet {
    const seedPhrase = generateSeedPhrase();

    const wallet = walletFromSeed(seedPhrase, { network: 'Preview' });
    const addressDetails: AddressDetails = getAddressDetails(wallet.address);
    console.log(`Wallet created with address: ${wallet.address}`);
    return {
      ...wallet,
      seedPhrase,
      verificationKey: toPublicKey(wallet.paymentKey),
      verificationKeyHash: addressDetails.paymentCredential!.hash,
    }
  }

  static getFundWallet(): SupplyChainWallet {
    const seedPhrase = SU.getEnvVar("FUND_WALLET_SEED_PHRASE");
    const verificationKey = SU.getEnvVar("FUND_VERIFICATION_KEY");
    const verificationKeyHash = SU.getEnvVar("FUND_VERIFICATION_KEY_HASH");
    const wallet = walletFromSeed(seedPhrase, { network: 'Preview' });
    return {
      ...wallet,
      seedPhrase,
      verificationKey,
      verificationKeyHash,
    }
  }

  static async registerProducts(lucid: LucidEvolution, wallets: SupplyChainWallet[]): Promise<string[]> {
    const pIndex = Math.floor(Math.random() * productsJson.length);
    const productTransactionMetadata: ProductMetadata = productsJson[pIndex];
    const tokenName = SU.getEnvVar("NFT_ASSET_NAME");
    const mintCompiledCode = SU.getRegisteredProductsMintCompiledCode();
    const script = applyDoubleCborEncoding(mintCompiledCode);
    const spendingValidator: SpendingValidator = { type: "PlutusV3", script };
    const mintingPolicy: MintingPolicy = { type: "PlutusV3", script };

    const policyId = mintingPolicyToId(mintingPolicy);
    const redeemer = Data.void();

    const datum = SU.generateCIP68Metadata(productTransactionMetadata);
    const validatorAddress = validatorToAddress('Preview', spendingValidator);
    const assetName = fromText(tokenName);
    const refUnit = toUnit(policyId, assetName, 100); // label 100 is dedicated for Reference NFT
    const userUnit = toUnit(policyId, assetName, 222); // label 222 is dedicated for NFT
    const userTokenQuantity = Math.floor(Math.random() * (10000 - 100 + 1)) + 100; // Random quantity from 100 to 10000
    const txHashes: string[] = [];
    // const date = new Date();
    // date.setHours(date.getHours() + 1);

    for (const wallet of wallets) {
      lucid.selectWallet.fromSeed(wallet.seedPhrase);

      const tx = lucid.newTx()
        .addSigner(wallet.address)
        .mintAssets(
          {
            [refUnit]: 1n,
            [userUnit]: BigInt(userTokenQuantity),
          },
          redeemer
        )
        .attach.MintingPolicy(mintingPolicy)
        // .attach.SpendingValidator(spendingValidator)
        // .validTo(date.getTime())
        .pay.ToContract(
          validatorAddress,
          { kind: "inline", value: datum },
          { [refUnit]: 1n }
        );
      const txToSign = await tx.complete();
      const signedTx = await txToSign.sign.withWallet().complete();
      const txHash = await signedTx.submit();
      console.log(`Product registered with tx hash: ${txHash}`);
      txHashes.push(txHash);
    }

    return txHashes;
  }

  private static generateCIP68Metadata(productMetadata: ProductMetadata): string {
    const { name, description, certificates, harvest_date, expiration_date, image, measurement } = productMetadata;
    const metadata = Data.fromJson({
      name, description, image,
      // Extra
      certificates, harvest_date: Date.parse(harvest_date),
      expiration_date: Date.parse(expiration_date), measurement
    });
    const version = BigInt(1);
    const cip68 = new Constr(0, [metadata, version]);

    const datum = Data.to(cip68);
    return datum;
  }

  private static createSignature(address: SupplyChainWallet, message: string): string {
    const privateKey = Cardano.PrivateKey.from_bech32(address.paymentKey);
    const messageBytes = new TextEncoder().encode(message);
    const signedMessage = privateKey.sign(messageBytes);
    const signature = Buffer.from(signedMessage.to_bytes()).toString("hex");
    return signature;
  }

  static async sendPayment(lucid: LucidEvolution, address: Address, lovelace: bigint): Promise<string> {
    const fundWallet = SU.getFundWallet();
    lucid.selectWallet.fromSeed(fundWallet.seedPhrase);

    const assets: Assets = { lovelace };
    const tx = await lucid.newTx()
      .pay.ToAddress(address, assets)
      .complete();

    const signedTx = await tx.sign.withPrivateKey(fundWallet.paymentKey).complete();
    const txHash = await signedTx.submit();
    console.log(`Payment submitted with tx hash: ${txHash}`);
    return txHash;
  }

  private static getRegisteredProductsMintCompiledCode(): string {
    return (plutusJson as PlutusJson).validators.find((v) => v.title.endsWith('register_products.register_products.mint'))!.compiledCode;
  }
}
