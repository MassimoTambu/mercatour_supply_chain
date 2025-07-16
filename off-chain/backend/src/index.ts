import { SupplyChainRunner } from "./runner.ts";
import { SU } from "./simulator_utils.ts";
import productsJson from "../products.json" with { type: "json" };
import { ProductAction } from "./interfaces/product_action.ts";

const runner = await SupplyChainRunner.init();

// const wallets = runner.createWallets(1);
const wallet = SU.getFundWallet();
const product = productsJson[3];
const productAction: ProductAction = {
  wallet,
  product,
  quantity: 22,
};
// await runner.mintProducts([productAction]);
// await runner.reMintProducts([productAction]);
// await runner.burnProducts([productAction]);
await runner.burnAllProducts([productAction]);
