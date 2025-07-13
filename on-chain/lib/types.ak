use aiken/crypto.{VerificationKeyHash}

pub type Action {
  Mint
  ReMint
  Burn
  BurnAll
}

pub type CIP68Datum {
  // Inside metadata we have the following keys:
  // Standard metadata
  //    name: ByteArray,
  //    description: ByteArray,
  //    image: ByteArray,
  metadata: Pairs<Data, Data>,
  version: Int,
  extra: ExtraDatum,
}

pub type ExtraDatum {
  certificates: List<ByteArray>,
  harvest_date: Int,
  expiration_date: Int,
  measurement: ByteArray,
  owner: VerificationKeyHash,
}
