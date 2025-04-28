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
DEPLOYMENT_OUTPUT=$(forge script script/execute/flash.s.sol:UniswapV3FlashTest \
  --rpc-url $SONIC_RPC \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --broadcast \
  --via-ir \
  --slow \
  --verify \
  --etherscan-api-key $SONIC_ETHERSCAN_ENDPOINT \
  --verifier custom \
  -vvvvv)