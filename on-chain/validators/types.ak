use aiken/crypto.{Signature, VerificationKey}

pub type RedeemerAction {
  RegisterProducts(RegisterProductsRedeemer)
}

pub type RegisterProductsRedeemer {
  verification_key: VerificationKey,
  message: ByteArray,
  signature: Signature,
}
