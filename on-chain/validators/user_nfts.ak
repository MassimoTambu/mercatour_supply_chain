use aiken/cbor
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

test serialize_verification_key_hashes() {
  let vkh: List<VerificationKeyHash> =
    [#"14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6"]
  cbor.serialise(vkh) == #"9f581c14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6ff"
}
