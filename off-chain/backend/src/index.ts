import { SupplyChainRunner } from "./runner.ts";
import { SU } from "./simulator_utils.ts";
import productsJson from "../products.json" with { type: "json" };

const runner = await SupplyChainRunner.init();

// const wallets = runner.createWallets(1);
const wallet = SU.getFundWallet();
const product = productsJson[3];
// await runner.registerProducts([wallet], [product]);
await runner.reMintProducts([wallet], [product]);
// await runner.burnProducts([wallet]);
