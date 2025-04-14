#!/bin/bash

# source ../utils/colors.sh

# # Deploy your protocol contracts
# echo -e "${BLUE}Deploying protocol contracts...${NC}"
forge script script/localnet/mint_tokens.s.sol:AnvilScript --fork-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -vvvvv