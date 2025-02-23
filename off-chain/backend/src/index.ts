import { SupplyChainRunner } from "./runner.ts";
import { SU } from "./simulator_utils.ts";

const runner = await SupplyChainRunner.init();

// const wallets = runner.createWallets(1);
const wallet = SU.getFundWallet();
await runner.registerProducts([wallet]);
