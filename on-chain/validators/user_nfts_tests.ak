use aiken/cbor
use aiken/crypto.{VerificationKeyHash}
use cardano/transaction.{Transaction}
use user_nfts

test serialize_verification_key_hashes() {
  let vkh: List<VerificationKeyHash> =
    [#"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed"]
  cbor.serialise(vkh) == #"9f581cb10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bedff"
}

test minting_policy() {
  let vkh: List<VerificationKeyHash> =
    [#"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed"]
  let policy_id = #"5772febcb5c28367cc64461c3b29d2ad27494341cb44e5aa9bfcb826"
  let tx =
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [
        #"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed",
      ],
    }
  user_nfts.user_nfts.mint(vkh, 0, policy_id, tx)
}
