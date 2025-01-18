import { getLucid } from './config';
import { createWallet } from './scripts';

const lucid = await getLucid();

// TODO initialize the database

const newWallet = createWallet();
console.log("Wallet Details:");
console.log("Payment Address:", newWallet.paymentAddress);
console.log("Signing Key (Private Key):", newWallet.signingKey);
console.log("Verification Key (Public Key):", newWallet.verificationKey);
