import * as Cardano from '@emurgo/cardano-serialization-lib-nodejs';
import { SupplyChainWallet } from './interfaces/wallet';
import { Lucid } from 'lucid-cardano';

export function getFundWallet(): SupplyChainWallet {
  if (process.env.FUND_ADDRESS === undefined) {
    throw new Error('FUND_ADDRESS is not defined');
  }

  if (process.env.FUND_SIGNING_KEY === undefined) {
    throw new Error('FUND_SIGNING_KEY is not defined');
  }

  if (process.env.FUND_VERIFICATION_KEY === undefined) {
    throw new Error('FUND_VERIFICATION_KEY is not defined');
  }

  return {
    paymentAddress: Cardano.Address.from_bech32(process.env.FUND_ADDRESS),
    signingKey: Cardano.PrivateKey.from_bech32(process.env.FUND_SIGNING_KEY),
    verificationKey: Cardano.PublicKey.from_bech32(process.env.FUND_VERIFICATION_KEY),
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
