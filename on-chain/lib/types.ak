pub type CIP68Datum {
  // Inside metadata we have the following keys:
  // Standard metadata
  //    name: ByteArray,
  //    description: ByteArray,
  //    image: ByteArray,
  // Extras
  //    certificates: List<ByteArray>,
  //    harvest_date: Int,
  //    expiration_date: Int,
  //    measurement: ByteArray,
  metadata: Pairs<Data, Data>,
  version: Int,
}
