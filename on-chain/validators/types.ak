use aiken/crypto.{Signature, VerificationKey}

pub type RegisterProductsRedeemer {
  verification_key: VerificationKey,
  message: ByteArray,
  signature: Signature,
}
