import { applyParamsToScript } from 'lucid-cardano';
import { SU } from "../simulator_utils.ts";

interface ConvertedBlueprint {
  "type": string;
  "description": string;
  "cborHex": string;
}

// * For now, we will only use one verification key hash.
const verificationKeyHash = SU.getEnvVar("FUND_VERIFICATION_KEY_HASH");
const paramsValidatorOutputFile = 'generated/user_nfts_mint_validator_params.json';

function getValidator(): ConvertedBlueprint {
  const cmd = new Deno.Command("aiken", {
    args: ["blueprint", "convert", "-m", "user_nfts", "-v", "user_nfts.mint"],
    cwd: "../on-chain/",
  });
  const { stdout, stderr, code } = cmd.outputSync();

  if (code !== 0) {
    console.error(new TextDecoder().decode(stderr));
    Deno.exit(1);
  }

  const userCertNFTValidator = JSON.parse(new TextDecoder().decode(stdout)) as ConvertedBlueprint;
  return userCertNFTValidator;
}

const validator = getValidator();

// Params for the validator
const verificationKeyHashes: string[] = [verificationKeyHash];

const paramsValidator = applyParamsToScript(validator.cborHex, [verificationKeyHashes]);

const userCertNFTValidatorParams: ConvertedBlueprint = {
  type: "PlutusScriptV3",
  description: "Parameterized User certificate NFT Aiken validator.",
  cborHex: paramsValidator
}

function writeJson(filePath: string, value: ConvertedBlueprint) {
  Deno.writeTextFileSync(filePath, JSON.stringify(value, null, 2));
}

writeJson(paramsValidatorOutputFile, userCertNFTValidatorParams);

console.log("Parameterized validator generated!");
