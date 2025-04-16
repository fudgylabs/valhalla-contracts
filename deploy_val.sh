#!/bin/bash

# Path to the script
SCRIPT_PATH="script/deploy_token.s.sol:AnvilScript"

echo "Running Forge script: $SCRIPT_PATH"

# Execute the forge script
# Add any required arguments after the script path
forge script $SCRIPT_PATH --broadcast --rpc-url http://localhost:8545

# Check if the script execution was successful
if [ $? -eq 0 ]; then
    echo "Successfully executed $SCRIPT_PATH"
else
    echo "Failed to execute $SCRIPT_PATH"
    exit 1
fi

echo "Script execution completed!"