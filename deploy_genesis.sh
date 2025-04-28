#!/bin/bash

# Load environment variables
if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found"
  exit 1
fi

# Check required environment variables
if [ -z "$SONIC_RPC" ] || [ -z "$SONIC_ETHERSCAN_ENDPOINT" ] || [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
  echo "Error: Missing required environment variables. Please check your .env file."
  echo "Required: SONIC_RPC, SONIC_ETHERSCAN_ENDPOINT, DEPLOYER_PRIVATE_KEY"
  exit 1
fi

# Create output directory for deployment artifacts
mkdir -p deployments

# Deploy the contracts
echo "Starting deployment of Valhalla and Genesis contracts..."

# Run the forge script with via-IR enabled and the specified RPC URL
DEPLOYMENT_OUTPUT=$(forge script script/deploy/genesis.s.sol:GenesisScript \
  --rpc-url $SONIC_RPC \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --via-ir \
  --slow \
  --verify \
  --etherscan-api-key $SONIC_ETHERSCAN_ENDPOINT \
  --verifier custom \
  -vvv)

# Save the full deployment output to a log file
echo "$DEPLOYMENT_OUTPUT" > deployments/deployment_log.txt

# Extract and save contract addresses
echo "Extracting deployed contract addresses..."

# Function to extract contract address from deployment output
extract_address() {
  local contract_name=$1
  local address=$(echo "$DEPLOYMENT_OUTPUT" | grep -A 3 "Contract Address: $contract_name" | grep -oE '0x[a-fA-F0-9]{40}' | head -1)
  
  if [ -z "$address" ]; then
    # Alternative extraction method if the first one fails
    address=$(echo "$DEPLOYMENT_OUTPUT" | grep -A 10 "$contract_name deployed" | grep -oE '0x[a-fA-F0-9]{40}' | head -1)
  fi
  
  echo $address
}

# Extract contract addresses
VALHALLA_ADDRESS=$(extract_address "Valhalla")
RAGNAROK_ADDRESS=$(extract_address "Ragnarok")
ZAP_ADDRESS=$(extract_address "VALZapIn")
# PAIR_ADDRESS=$(extract_address "pair")

# Create JSON files with contract addresses
cat > deployments/valhalla.json << EOF
{
  "name": "Valhalla",
  "address": "$VALHALLA_ADDRESS",
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)"
}
EOF

cat > deployments/ragnarok.json << EOF
{
  "name": "Ragnarok",
  "address": "$RAGNAROK_ADDRESS",
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)"
}
EOF

cat > deployments/zap.json << EOF
{
  "name": "VALZapIn",
  "address": "$ZAP_ADDRESS",
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)"
}
EOF

# cat > deployments/pair.json << EOF
# {
#   "name": "VAL-OS Pair",
#   "address": "$PAIR_ADDRESS",
#   "network": "sonic",
#   "deploymentTimestamp": "$(date +%s)"
# }
# EOF

# Create a consolidated JSON file with all addresses
cat > deployments/all_contracts.json << EOF
{
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)",
  "contracts": {
    "Valhalla": "$VALHALLA_ADDRESS",
    "Ragnarok": "$RAGNAROK_ADDRESS",
    "VALZapIn": "$ZAP_ADDRESS"
  }
}
EOF

# Verify contracts if they weren't automatically verified during deployment
verify_contract() {
  local contract_name=$1
  local address=$2
  local constructor_args=$3
  
  echo "Verifying $contract_name at $address..."
  
  forge verify-contract \
    --chain-id 146 \
    --compiler-version "v0.8.28+commit.8e97aaf3" \
    --num-of-optimizations 200 \
    --watch \
    --constructor-args $constructor_args \
    --verifier etherescan \
    --verifier-url $SONIC_ETHERSCAN_ENDPOINT?$ETHERSCAN_API_KEY \
    --via-ir
    $address \
    src/$contract_name.sol:$contract_name
}

# Only run verification if addresses were found but not verified during deployment
if [[ $DEPLOYMENT_OUTPUT != *"Contract verification successful"* ]]; then
  if [ ! -z "$VALHALLA_ADDRESS" ]; then
    verify_contract "Valhalla" $VALHALLA_ADDRESS ""
  fi
  
  if [ ! -z "$RAGNAROK_ADDRESS" ]; then
    # Construct ABI-encoded constructor arguments for Ragnarok
    RAGNAROK_ARGS=$(cast abi-encode "constructor(address,address,uint256,address)" $VALHALLA_ADDRESS $DEVFUND 1744830000 $SHADOW_VOTER)
    verify_contract "distribution/Ragnarok" $RAGNAROK_ADDRESS $RAGNAROK_ARGS
  fi
  
  if [ ! -z "$ZAP_ADDRESS" ]; then
    # Construct ABI-encoded constructor arguments for VALZapIn
    ZAP_ARGS=$(cast abi-encode "constructor(address,address,address)" $VALHALLA_ADDRESS $OS $SHADOW_ROUTER)
    verify_contract "zap" $ZAP_ADDRESS $ZAP_ARGS
  fi
fi

# Print summary
echo "=== Deployment Summary ==="
echo "Valhalla: $VALHALLA_ADDRESS"
echo "Ragnarok: $RAGNAROK_ADDRESS"
echo "VALZapIn: $ZAP_ADDRESS"
# echo "VAL-OS Pair: $PAIR_ADDRESS"
echo "Deployment artifacts saved to ./deployments/"
echo "=========================="