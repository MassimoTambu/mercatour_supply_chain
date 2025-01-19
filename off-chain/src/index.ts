import dotenv from "dotenv";
import { getFundWallet } from "./cardano_utils";

dotenv.config();

const wallet = getFundWallet();
const vkhHex = Buffer.from(wallet.verificationKey.hash().to_bytes()).toString('hex');
console.log(vkhHex);



// TODO initialize the database

// const newWallet = createWallet();
// console.log("Wallet Details:");
// console.log("Payment Address:", newWallet.paymentAddress);
// console.log("Signing Key (Private Key):", newWallet.signingKey);
// console.log("Verification Key (Public Key):", newWallet.verificationKey);

// const utxos = await lucid.utxosAt(process.env.FUND_ADDRESS!);
// // Calculate the total ADA (lovelace)
// const totalLovelace = utxos.reduce((sum, utxo) => sum + BigInt(utxo.assets['lovelace']), BigInt(0));

// // Convert lovelace to ADA (1 ADA = 1,000,000 lovelace)
// const totalAda = Number(totalLovelace) / 1_000_000;
// console.log("Total ADA:", totalAda);
