use aiken/crypto.{VerificationKeyHash}

validator user_nfts(
  token_name: ByteArray,
  verification_key_hashes: List<VerificationKeyHash>,
) {
  // - Check if minting policy condition returns true
  // mint(_redeemer: Redeemer, policy_id: PolicyId, self: Transaction) {
  //   todo
  // }

  else(_) {
    fail
  }
}
