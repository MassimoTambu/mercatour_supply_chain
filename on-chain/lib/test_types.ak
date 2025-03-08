use cardano/assets.{PolicyId, Value}
use types.{CIP68Datum}

pub type TestAssetData {
  value: Value,
  datum: Option<CIP68Datum>,
  policy_id: Option<PolicyId>,
}
