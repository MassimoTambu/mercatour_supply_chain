use aiken/cbor
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/transaction.{OutputReference, Transaction}
use old/custom_types.{UserCertificateDatum, UserCertificateExtraDatum}
use old/user_nfts

/// Sat Feb 02 2030 17:06:10 GMT+0000
const expiration = 1896282370

/// Sun Feb 02 2025 17:06:10 GMT+0000
const upper_bound_success =
  IntervalBound { bound_type: Finite(1738515970), is_inclusive: True }

/// Thu Nov 22 2029 00:39:30 GMT+0000
const upper_bound_failure =
  IntervalBound { bound_type: Finite(1890002370), is_inclusive: True }

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
      validity_range: Interval {
        lower_bound: IntervalBound { bound_type: Finite(1), is_inclusive: True },
        upper_bound: upper_bound_success,
      },
    }
  user_nfts.user_nfts.mint(vkh, 0, policy_id, tx)
}

test spend_success() {
  let vkh: List<VerificationKeyHash> =
    [#"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed"]
  let datum =
    UserCertificateDatum {
      name: "test",
      description: "Test desc",
      image: "Test image url",
      meta_version: 0,
      extra: Pair(0, UserCertificateExtraDatum { expiration }),
    }
  let utxo =
    OutputReference {
      transaction_id: transaction.placeholder.id,
      output_index: 1,
    }
  let tx =
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [
        #"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed",
      ],
      validity_range: Interval {
        lower_bound: IntervalBound { bound_type: Finite(1), is_inclusive: True },
        upper_bound: upper_bound_success,
      },
    }
  user_nfts.user_nfts.spend(vkh, Some(datum), 0, utxo, tx)
}

test spend_expiration_timestamp_is_less_than_one_year_from_tx_validity() fail {
  let vkh: List<VerificationKeyHash> =
    [#"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed"]
  let datum =
    UserCertificateDatum {
      name: "test",
      description: "Test desc",
      image: "Test image url",
      meta_version: 0,
      extra: Pair(0, UserCertificateExtraDatum { expiration: 1896282370 }),
    }
  let utxo =
    OutputReference {
      transaction_id: transaction.placeholder.id,
      output_index: 1,
    }
  let tx =
    Transaction {
      ..transaction.placeholder,
      extra_signatories: [
        #"b10a62f80182d7162ea2c1763d88fd59eed044fb1e34508175425bed",
      ],
      validity_range: Interval {
        lower_bound: IntervalBound { bound_type: Finite(1), is_inclusive: True },
        upper_bound: upper_bound_failure,
      },
    }
  user_nfts.user_nfts.spend(vkh, Some(datum), 0, utxo, tx)
}
