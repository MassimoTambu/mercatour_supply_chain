#!/bin/bash

# Define variables
KEYS_DIR="/home/ubuntu/food_supply_chain/keys"
NUM_ADDRESSES=$1

# Check if the number of addresses is provided
if [ -z "$NUM_ADDRESSES" ]; then
  echo "Usage: $0 <number_of_addresses>"
  exit 1
fi

# Create directory for keys if it doesn't exist
mkdir -p $KEYS_DIR

# Loop through and generate the specified number of addresses
for i in $(seq 1 $NUM_ADDRESSES); do
  ADDRESS_NAME="address$i"
  # Generate payment keys
  cardano-cli address key-gen \
     --verification-key-file $KEYS_DIR/$ADDRESS_NAME.vkey \
     --signing-key-file $KEYS_DIR/$ADDRESS_NAME.skey

  # Generate stake keys
  cardano-cli stake-address key-gen \
     --verification-key-file $KEYS_DIR/$ADDRESS_NAME-stake.vkey \
     --signing-key-file $KEYS_DIR/$ADDRESS_NAME-stake.skey

  # Generate the address
  cardano-cli address build \
     --payment-verification-key-file $KEYS_DIR/$ADDRESS_NAME.vkey \
     --stake-verification-key-file $KEYS_DIR/$ADDRESS_NAME-stake.vkey \
     --out-file $KEYS_DIR/$ADDRESS_NAME.addr \
     --testnet-magic 2

  echo "Address $ADDRESS_NAME created and saved to $KEYS_DIR/$ADDRESS_NAME.addr"
done
