import { applyParamsToScript } from 'lucid-cardano';

interface ConvertedBlueprint {
  "type": string;
  "description": string;
  "cborHex": string;
}

if (Deno.args.length !== 1) {
  console.error("Please provide the validator file and the output file path.");
  Deno.exit(1);
}

// * For now, we will only use one verification key hash.
const verificationKeyHash = Deno.env.get("FUND_VERIFICATION_KEY_HASH");
if (verificationKeyHash == undefined) {
  console.error("Please set the FUND_VERIFICATION_KEY_HASH in the env file.");
  Deno.exit(1);
}

// const validatorAiken = applyDoubleCborEncoding("59024c01010032323232323232223225333005323232323253323300b3001300c3754004264a6660186004601a6ea80104c8c8c8c8c8c8c8c94ccc05cc0680084c94ccc054c8cc004004dd6180d980c1baa01022533301a00114a0264a66603066ebcc010c068dd5180e80100b8a51133003003001301d00115332330163232533301b301e00213253330193004375a6036004266e3c0040585281bae301900116301c001325333017300230183754002297adef6c6013756603860326ea8004c8cc004004dd5980e180e980e980e980e980c9baa01122533301b00114c103d87a8000132323232533301c337220220042a66603866e3c0440084cdd2a4000660406e980052f5c02980103d87a80001330060060033756603a0066eb8c06c008c07c008c0740044c94ccc05cc0340044c8c8cc004004dd6180f180f980f980f980f980f980f980f980f980d9baa01322533301d00114a0264a66603666e3cdd718100010020a511330030030013020001375c6038603a603a60326ea803c54ccc05cc0080044c8cc88c94ccc06cc018c070dd5000899b89002375a6040603a6ea80045281803180e1baa3003301c3754004603a603c603c603c603c603c603c603c60346ea8048dd69800980d1baa0102301d301e00114a06eb4c008c060dd50071b87480085280a502301a00116375a603000260300046eb8c058004c058008dd6980a000980a0011bad3012001300e37540082c6eb8c040c034dd50011b874800058c038c03c008c034004c034008c02c004c01cdd50008a4c26cac6eb80055cd2ab9d5573caae7d5d02ba157441")

const paramsValidatorOutputFile: string = Deno.args[0];

async function getValidator(): Promise<ConvertedBlueprint> {
  const cmd = new Deno.Command("aiken", {
    args: ["blueprint", "convert", "-m", "user_nfts", "-v", "user_nfts.mint"],
    cwd: "../on-chain/",
  });
  const { stdout, stderr } = await cmd.output();
  console.log();
  if (stderr.length > 0) {
    console.error(new TextDecoder().decode(stderr));
    Deno.exit(1);
  }

  const userCertNFTValidator = JSON.parse(new TextDecoder().decode(stdout)) as ConvertedBlueprint;
  return userCertNFTValidator;
}

const validator = await getValidator();

// Params for the validator
const verificationKeyHashes: string[] = [verificationKeyHash];

const paramsValidator = applyParamsToScript(validator.cborHex, [verificationKeyHashes]);
// const paramsAikenValidator = applyParamsToScript(validatorAiken, [verificationKeyHashes]);

const userCertNFTValidatorParams: ConvertedBlueprint = {
  type: "PlutusScriptV3",
  description: "Parameterized User certificate NFT Aiken validator.",
  cborHex: paramsValidator
}

// console.log(params_ea_nft_val);

async function writeJson(filePath: string, value: ConvertedBlueprint) {
  await Deno.writeTextFile(filePath, JSON.stringify(value, null, 2));
}

await writeJson(paramsValidatorOutputFile, userCertNFTValidatorParams);

console.log("PARAMETERIZED VALIDATOR CREATED!");
