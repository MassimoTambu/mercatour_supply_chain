import * as Cardano from '@emurgo/cardano-serialization-lib-nodejs';

export function createWallet() {
  // Generate a private key (Ed25519)
  const privateKey = Cardano.PrivateKey.generate_ed25519();

  // Derive the public key from the private key
  const publicKey = privateKey.to_public();

  // Generate a payment address using the public key and the mainnet network ID
  const baseAddress = Cardano.BaseAddress.new(
    Cardano.NetworkInfo.testnet_preview().network_id(),
    Cardano.Credential.from_keyhash(publicKey.hash()),
    Cardano.Credential.from_keyhash(publicKey.hash()) // Dummy stake credential
  );

  // Convert the address, private key, and public key to strings
  const wallet = {
    paymentAddress: baseAddress.to_address().to_bech32(),
    signingKey: privateKey.to_bech32(),
    verificationKey: publicKey.to_bech32()
  };

  return wallet;
}
