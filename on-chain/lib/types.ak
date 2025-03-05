pub type RegisterProductsDatum {
  product_name: ByteArray,
  certificates: List<ByteArray>,
  harvest_date: Int,
  expiration_date: Int,
  unit_of_measurement: ByteArray,
}
