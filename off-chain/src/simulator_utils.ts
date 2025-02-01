import { SupplyChainWallet } from './interfaces/supply_chain_wallet.ts';
import { LucidEvolution, walletFromSeed } from '@lucid-evolution/lucid';
import { fromText } from '@lucid-evolution/core-utils';
import { Data } from '@lucid-evolution/plutus';
import { AddressDetails, MintingPolicy } from "@lucid-evolution/core-types";
import { applyDoubleCborEncoding, applyParamsToScript, generateSeedPhrase, getAddressDetails, mintingPolicyToId, toPublicKey } from "@lucid-evolution/utils";
import { PlutusJson } from "./interfaces/plutus_json.ts";

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

    console.log("Wallet seedPhrase:", seedPhrase);
    const wallet = walletFromSeed(seedPhrase, { network: 'Preview' });
    const addressDetails: AddressDetails = getAddressDetails(wallet.address);
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

  // * This is the old implementation of createUserNFTCertificate, where I used the policyId 
  // * and the parameterized validator blueprint generated by aiken cli.
  // static async createUserNFTCertificate(lucid: LucidEvolution): Promise<void> {
  //   const fundAddress = SU.getEnvVar("FUND_ADDRESS");
  //   const signerKey = SU.getEnvVar("FUND_SIGNING_KEY");
  //   const policyId = Deno.readTextFileSync('generated/user_nfts_policy_id').trim();
  //   const tokenName = SU.getEnvVar("USER_NFT_CERTIFICATE_NAME");
  //   const validatorBlueprint = JSON.parse(Deno.readTextFileSync('generated/user_nfts_mint_validator_params.json')) as ConvertedBlueprint;
  //   const mintingPolicy: Script = { type: "PlutusV3", script: applyDoubleCborEncoding(validatorBlueprint.cborHex) };

  //   const redeemer = Data.void();

  //   const unit = policyId + fromText(tokenName);
  //   const date = new Date();
  //   date.setHours(date.getHours() + 1);

  //   lucid.selectWallet.fromPrivateKey(signerKey);

  //   const tx = await lucid.newTx()
  //     .mintAssets({ [unit]: 1n }, redeemer)
  //     .pay.ToAddress(fundAddress, { [unit]: 1n })
  //     .validTo(date.getTime())
  //     .attach.MintingPolicy(mintingPolicy)
  //     .complete();

  //   const signedTx = await tx.sign.withPrivateKey(signerKey).complete();
  //   // const txHash = await signedTx.submit();
  //   // console.log(`User NFT Certificate minted with tx hash: ${txHash}`);
  // }

  // * In this new implementation, the policyId is generated in the code itself
  // * and the validator blueprint is read from the plutus.json file.
  static async createUserNFTCertificate(lucid: LucidEvolution): Promise<void> {
    const fundWallet = SU.getFundWallet();
    const tokenName = SU.getEnvVar("USER_NFT_CERTIFICATE_NAME");
    const mintCompiledCode = SU.getPlutusMintCompiledCode();
    const mintingPolicy: MintingPolicy = {
      type: "PlutusV3", script:
        applyParamsToScript(
          applyDoubleCborEncoding(mintCompiledCode),
          [[fundWallet.verificationKeyHash]]
        ),
    };

    const policyId = mintingPolicyToId(mintingPolicy);
    const redeemer = Data.void();

    const metadataCBOR = SU.generateMetadata();
    const unit = policyId + fromText(tokenName);
    const date = new Date();
    date.setHours(date.getHours() + 1);

    lucid.selectWallet.fromSeed(fundWallet.seedPhrase);

    const tx = await lucid.newTx()
      .addSigner(fundWallet.address)
      .mintAssets({ [unit]: 1n }, redeemer)
      .pay.ToAddressWithData(fundWallet.address,
        { kind: "inline", value: metadataCBOR },
        { [unit]: 1n })
      .validTo(date.getTime())
      .attach.MintingPolicy(mintingPolicy)
      .complete();

    const signedTx = await tx.sign.withPrivateKey(fundWallet.paymentKey).complete();
    const txHash = await signedTx.submit();
    console.log(`User NFT Certificate minted with tx hash: ${txHash}`);
  }

  private static getPlutusMintCompiledCode(): string {
    const validatorBlueprint = JSON.parse(Deno.readTextFileSync('../on-chain/plutus.json')) as PlutusJson;
    return validatorBlueprint.validators.find((v) => (v.title).endsWith('.mint'))!.compiledCode;
  }

  private static generateMetadata(): string {
    const CIP68DatumSchema = Data.Object({
      metadata: Data.Map(Data.Any(), Data.Any()),
      version: Data.Integer(),
    });
    type CIP68DatumSchemaType = Data.Static<typeof CIP68DatumSchema>;
    const CIP68Datum = CIP68DatumSchema as unknown as CIP68DatumSchemaType;

    const metadataMap = new Map();
    // TODO take next id from the database
    // id: 1,
    metadataMap.set(fromText("name"), Data.to(fromText("Mercatour 2025 Supplychain User Certificate")));
    metadataMap.set(fromText("description"), Data.to(fromText("This NFT certficates that the possessor can use the Mercatour Supplychain for the year 2025.")));
    metadataMap.set(fromText("image"), Data.to(fromText("https://waapple.org/wp-content/uploads/2021/06/Variety_Cosmic-Crisp-transparent-658x677.png")));
    // TODO get entity name and address from the database
    // entity: {
    //   name: "Salami Inc.",
    //   address: "Via della Salamella 1, 12345 Salami City, Italy"
    // }
    const metadataCBOR = Data.to(
      { metadata: metadataMap, version: 0n },
      CIP68Datum
    );

    return metadataCBOR;
  }
}
