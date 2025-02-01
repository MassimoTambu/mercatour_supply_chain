import { SU } from "./simulator_utils.ts";

const wallet = SU.generateWallet();
console.log("Wallet Details:");
console.log("Payment Address:", wallet.address);
console.log("Signing Key (Private Key):", wallet.paymentKey);
console.log("Verification Key (Public Key):", wallet.verificationKey);
console.log("Verification Key Hash:", wallet.verificationKeyHash);
console.log("Reward Address:", wallet.rewardAddress);
console.log("Stake Key:", wallet.stakeKey);
