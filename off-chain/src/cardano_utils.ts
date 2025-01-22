import * as Cardano from '@emurgo/cardano-serialization-lib-nodejs';
import { SupplyChainWallet } from './interfaces/wallet.ts';
import { Lucid } from 'lucid-cardano';

export function getFundWallet(): SupplyChainWallet {
  const fundAddress = Deno.env.get("FUND_ADDRESS");
  if (fundAddress === undefined) {
    throw new Error('FUND_ADDRESS is not defined');
  }

  const fundSigningKey = Deno.env.get("FUND_SIGNING_KEY");
  if (fundSigningKey === undefined) {
    throw new Error('FUND_SIGNING_KEY is not defined');
  }

  const fundVerificationKey = Deno.env.get("FUND_VERIFICATION_KEY");
  if (fundVerificationKey === undefined) {
    throw new Error('FUND_VERIFICATION_KEY is not defined');
  }

  return {
    paymentAddress: Cardano.Address.from_bech32(fundAddress),
    signingKey: Cardano.PrivateKey.from_bech32(fundSigningKey),
    verificationKey: Cardano.PublicKey.from_bech32(fundVerificationKey),
  };
}

export function createWallet(): SupplyChainWallet {
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

// export function createNFTCertificate(wallet: SupplyChainWallet, policyId: string, assetName: string): Cardano.Certificate {
//   const mint = Cardano.MintAssets.(Buffer.from(policyId, 'hex'), Buffer.from(assetName, 'utf8'));
//   return Cardano.Certificate.new_stake_credential_registration(wallet.verificationKey.hash(), mint);
// }

// function mintingPolicy(lucid: Lucid) {

//   const mintingPolicy = lucid.utils.nativeScriptFromJson(
//     {
//       type: "all",
//       scripts: [
//         { type: "sig", keyHash: paymentCredential.hash },
//         {
//           type: "before",
//           slot: lucid.utils.unixTimeToSlot(Date.now() + 1000000),
//         },
//       ],
//     },
//   );
// }
