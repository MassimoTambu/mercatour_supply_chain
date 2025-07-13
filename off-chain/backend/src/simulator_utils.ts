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

  static async registerProducts(lucid: LucidEvolution, wallets: SupplyChainWallet[], products: ProductMetadata[]): Promise<string[]> {
    const tokenName = SU.getEnvVar("NFT_ASSET_NAME");
    const mintCompiledCode = SU.getRegisteredProductsMintCompiledCode();
    const script = applyDoubleCborEncoding(mintCompiledCode);
    const spendingValidator: SpendingValidator = { type: "PlutusV3", script };
    const mintingPolicy: MintingPolicy = { type: "PlutusV3", script };

    const policyId = mintingPolicyToId(mintingPolicy);
    const redeemer = Data.to(new Constr(0, []));
    // In case of empty redeemer, uncomment the line below
    // const redeemer = Data.void();


    const validatorAddress = validatorToAddress('Preview', spendingValidator);
    const assetName = fromText(tokenName);
    const refUnit = toUnit(policyId, assetName, 100); // label 100 is dedicated for Reference NFT
    const userUnit = toUnit(policyId, assetName, 222); // label 222 is dedicated for NFT
    const userTokenQuantity = Math.floor(Math.random() * (10000 - 100 + 1)) + 100; // Random quantity from 100 to 10000
    const txHashes: string[] = [];
    // const date = new Date();
    // date.setHours(date.getHours() + 1);

    for (const index in wallets) {
      const wallet = wallets[index];
      const productTransactionMetadata = products[index]
      const datum = SU.generateCIP68Metadata(wallet, productTransactionMetadata);
      lucid.selectWallet.fromSeed(wallet.seedPhrase);

      const tx = lucid.newTx()
        // Needed to compare vkh in the metadata
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

  private static generateCIP68Metadata(wallet: SupplyChainWallet, productMetadata: ProductMetadata): string {
    const { name, description, certificates, harvest_date, expiration_date, image, measurement } = productMetadata;
    const metadata = Data.fromJson({ name, description, image });
    const version = BigInt(1);
    const extra = new Constr(0, [
      certificates.map(c => fromText(c)),
      BigInt(Date.parse(harvest_date)),
      BigInt(Date.parse(expiration_date)),
      fromText(measurement),
      wallet.verificationKeyHash,
    ])

    const cip68 = new Constr(0, [metadata, version, extra]);

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

  static async reMintProducts(lucid: LucidEvolution, wallets: SupplyChainWallet[], products: ProductMetadata[]): Promise<string[]> {
    const tokenName = SU.getEnvVar("NFT_ASSET_NAME");
    const mintCompiledCode = SU.getRegisteredProductsMintCompiledCode();
    const script = applyDoubleCborEncoding(mintCompiledCode);
    const spendingValidator: SpendingValidator = { type: "PlutusV3", script };
    const mintingPolicy: MintingPolicy = { type: "PlutusV3", script };

    const policyId = mintingPolicyToId(mintingPolicy);
    const redeemer = Data.to(new Constr(0, []));
    // In case of empty redeemer, uncomment the line below
    // const redeemer = Data.void();


    const validatorAddress = validatorToAddress('Preview', spendingValidator);
    const assetName = fromText(tokenName);
    const refUnit = toUnit(policyId, assetName, 100); // label 100 is dedicated for Reference NFT
    const userUnit = toUnit(policyId, assetName, 222); // label 222 is dedicated for NFT
    const userTokenQuantity = Math.floor(Math.random() * (10000 - 100 + 1)) + 100; // Random quantity from 100 to 10000
    const txHashes: string[] = [];
    // const date = new Date();
    // date.setHours(date.getHours() + 1);

    const utxos = await lucid.utxosAt(validatorAddress)

    for (const index in wallets) {
      const wallet = wallets[index];
      const productTransactionMetadata = products[index]
      const datum = SU.generateCIP68Metadata(wallet, productTransactionMetadata);
      const validatorUtxo = utxos.find((utxo) => utxo.datum === datum)!;

      lucid.selectWallet.fromSeed(wallet.seedPhrase);

      const tx = lucid.newTx()
        // Needed to compare vkh in the metadata
        .addSigner(wallet.address)
        .collectFrom([validatorUtxo], redeemer)
        .mintAssets(
          {
            [refUnit]: 1n,
            [userUnit]: BigInt(userTokenQuantity),
          },
          redeemer
        )
        .attach.MintingPolicy(mintingPolicy)
        .attach.SpendingValidator(spendingValidator)
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

  static async burnProducts(lucid: LucidEvolution, wallets: SupplyChainWallet[], products: ProductMetadata[]): Promise<string[]> {
    const tokenName = SU.getEnvVar("NFT_ASSET_NAME");
    const mintCompiledCode = SU.getRegisteredProductsMintCompiledCode();
    const script = applyDoubleCborEncoding(mintCompiledCode);
    const spendingValidator: SpendingValidator = { type: "PlutusV3", script };
    const mintingPolicy: MintingPolicy = { type: "PlutusV3", script };

    const policyId = mintingPolicyToId(mintingPolicy);
    const redeemer = Data.to(new Constr(1, []));
    // In case of empty redeemer, uncomment the line below
    // const redeemer = Data.void();

    const validatorAddress = validatorToAddress('Preview', spendingValidator);
    const assetName = fromText(tokenName);
    const refUnit = toUnit(policyId, assetName, 100); // label 100 is dedicated for Reference NFT
    const userUnit = toUnit(policyId, assetName, 222); // label 222 is dedicated for NFT
    const txHashes: string[] = [];
    // const date = new Date();
    // date.setHours(date.getHours() + 1);

    for (const wallet of wallets) {
      // Take the first UTXO that contains the user unit.
      // I cannot filter for metadata, because the metadata is stored in the UTXO of the validator
      const utxo = (await lucid.utxosAt(wallet.address)).find((utxo) => utxo.assets[userUnit] && utxo.assets[userUnit] > 0n);
      const userUnitAsset = utxo?.assets[userUnit];

      if (!utxo || !userUnitAsset) {
        console.error(`No UTXO found for user unit: ${userUnit} at address: ${wallet.address}`);
        continue;
      }

      // Get the reference NFT in the locked script address of the validator
      const validatorUtxo = (await lucid.utxosAt(validatorAddress)).find((utxo) => utxo.assets[refUnit] && utxo.assets[refUnit] === 1n);
      const refUnitAsset = validatorUtxo?.assets[refUnit];

      if (!validatorUtxo || !refUnitAsset) {
        console.error(`No validator UTXO found for ref unit: ${refUnit} at address: ${validatorAddress}`);
        continue;
      }

      lucid.selectWallet.fromSeed(wallet.seedPhrase);

      const tx = lucid
        .newTx()
        // Needed to compare vkh in the metadata
        .addSigner(wallet.address)
        .collectFrom([utxo, validatorUtxo], redeemer)
        .attach.MintingPolicy(mintingPolicy)
        .attach.SpendingValidator(spendingValidator)
        // .validTo(date.getTime())
        .mintAssets(
          {
            [refUnit]: -refUnitAsset,
            [userUnit]: -userUnitAsset,
          },
          redeemer
        );

      const txToSign = await tx.complete();
      const signedTx = await txToSign.sign.withWallet().complete();
      const txHash = await signedTx.submit();

      console.log(`Product burned with tx hash: ${txHash}`);
      txHashes.push(txHash);
    }

    return txHashes;
  }
}
