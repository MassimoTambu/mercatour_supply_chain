pub type UserCertificateDatum {
  name: ByteArray,
  description: ByteArray,
  image: ByteArray,
  meta_version: Int,
  extra: Pair<Int, UserCertificateExtraDatum>,
}

pub type UserCertificateExtraDatum {
  expiration: Int,
}

pub type UserCertificateDatumV2 {
  // Verification Key
  owner: ByteArray,
  expiration: Int,
}
