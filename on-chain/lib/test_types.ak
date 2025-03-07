use cardano/assets.{PolicyId, Value}
use types.{RegisterProductsDatum}

pub type TestAssetData {
  value: Value,
  datum: Option<RegisterProductsDatum>,
  policy_id: Option<PolicyId>,
}
