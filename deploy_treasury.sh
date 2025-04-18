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
DEPLOYMENT_OUTPUT=$(forge script script/deploy/deploy_boardroom.s.sol:BoardroomScript \
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
TREASURY_ADDRESS=$(extract_address "Boardroom")
# Create JSON files with contract addresses
cat > deployments/boardroom.json << EOF
{
  "name": "Boardroom",
  "address": "$TREASURY_ADDRESS",
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)"
}
EOF

# Create a consolidated JSON file with all addresses
cat > deployments/all_contracts2.json << EOF
{
  "network": "sonic",
  "deploymentTimestamp": "$(date +%s)",
  "contracts": {
    "Boardroom": "$TREASURY_ADDRESS"
  }
}
EOF
