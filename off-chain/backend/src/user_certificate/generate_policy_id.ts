import { SU } from "../simulator_utils.ts";

// * For now, we will only use one serialized verification key.
const serialized_verification_keys = SU.getEnvVar("FUND_SERIALIZED_VERIFICATION_KEY");

const generateParameterizedPlutusJson = new Deno.Command("aiken", {
  args: ["blueprint", "apply", serialized_verification_keys, "-m", "user_nfts", "-v", "user_nfts.mint"],
  cwd: "../../on-chain/",
});

let { stdout, stderr, code } = await generateParameterizedPlutusJson.output();
if (code !== 0) {
  console.error(new TextDecoder().decode(stderr));
  Deno.exit(1);
}

const parameterizedPlutusJson = new TextDecoder().decode(stdout);

Deno.renameSync("../../on-chain/plutus.json", "../../on-chain/plutus_temp.json");

const encoder = new TextEncoder();
const plutusJson = encoder.encode(parameterizedPlutusJson);
Deno.writeFileSync("../../on-chain/plutus.json", plutusJson);

const generatePolicyId = new Deno.Command("aiken", {
  args: ["blueprint", "policy", "-m", "user_nfts", "-v", "user_nfts.mint"],
  cwd: "../../on-chain/",
});
({ stdout, stderr, code } = await generatePolicyId.output());
if (code !== 0) {
  console.error(new TextDecoder().decode(stderr));
  Deno.exit(1);
}

const policyId = new TextDecoder().decode(stdout);
console.log("Policy ID generated: " + policyId);

Deno.writeTextFileSync("generated/user_nfts_policy_id", policyId);
Deno.removeSync("../../on-chain/plutus.json");
Deno.renameSync("../../on-chain/plutus_temp.json", "../../on-chain/plutus.json");
