use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}

validator user_nfts(verification_key_hashes: List<VerificationKeyHash>) {
  // - Check if minting policy condition returns true
  mint(_redeemer: Data, _policy_id: PolicyId, self: Transaction) {
    // Check if the transaction is signed by at least one authorized VKH
    self.extra_signatories
      |> list.any(fn(signer) { verification_key_hashes |> list.has(signer) })
  }

  else(_) {
    fail
  }
}
