use aiken/cbor
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{Transaction}
use user_nfts

test serialize_verification_key_hashes() {
  let vkh: List<VerificationKeyHash> =
    [#"14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6"]
  cbor.serialise(vkh) == #"9f581c14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6ff"
}

test minting_policy() {
  let vkh: List<VerificationKeyHash> =
    [#"14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6"]
  let policy_id = #"59e7d2e2d550e697aa838fc6d0230d824653ed62170d9fdc1822e7e8"
  let tx =
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [
        #"14852fef5f1ffefd230108d16eab932863a2158b23ff935e4e4f13d6",
      ],
    }
  user_nfts.user_nfts.mint(vkh, 0, policy_id, tx)
}
