export interface PlutusJson {
  preamble: {
    title: string;
    description: string;
    version: string;
    plutusVersion: string;
    compiler: {
      name: string;
      version: string;
    };
    license: string;
  };
  validators: Validator[];
  definitions: unknown;
}

export interface Validator {
  title: string;
  datum?: ValidatorProperty;
  redeemer?: ValidatorProperty;
  parameters?: ValidatorProperty[];
  compiledCode: string;
  hash: string;
}

export interface ValidatorProperty {
  title: string,
  schema: {
    $ref: string
  }
}


