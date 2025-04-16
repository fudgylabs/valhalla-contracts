#!/bin/bash

# Function selector for mintTo(address,uint256)
# This is the first 4 bytes of the keccak256 hash of "mintTo(address,uint256)"
MINT_SELECTOR="0x449a52f8"

# Define recipient addresses
RECIPIENT1="0x9142D6FFD7907f0A64B9Cf1A742E2E3c5B0bd00c"
RECIPIENT2="0x04301b0c3bC192C28DD3CAF345C4aE6E979EC040"

# Amount to mint (50 ether = 50 * 10^18)
AMOUNT="50000000000000000000"

# Define all token addresses
declare -a TOKEN_ADDRESSES=(
    "0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794" # OS
    "0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE" # SCUSD
    "0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812" # SCETH
    "0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd" # SCBTC
    "0xE5DA20F15420aD15DE0fa650600aFc998bbE3955" # STS
    "0x3333b97138D4b086720b5aE8A7844b1345a33333" # SHADOW
    "0x3333111A391cC08fa51353E9195526A70b333333" # X33
    "0x7A0C53F7eb34C5BC8B01691723669adA9D6CB384" # BOO
    "0xddF26B42C1d903De8962d3F79a74a501420d5F19" # EQUAL
    "0xf26Ff70573ddc8a90Bd7865AF8d7d70B8Ff019bC" # EGGS
    "0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C" # ANON
    "0xe920d1DA9A4D59126dC35996Ea242d60EFca1304" # DERP
    "0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564" # GOGLZ
    "0x6fB9897896Fe5D05025Eb43306675727887D0B7c" # HEDGY
    "0x31E2eed04a62b232DA964A097D8C171584e3C3Bd" # OIL
    "0xf4F9C50455C698834Bb645089DbAa89093b93838" # TOONA
    "0xE51EE9868C1f0d6cd968A8B8C8376Dc2991BFE44" # BRUSH
    "0x7A08Bf5304094CA4C7b4132Ef62b5EDc4a3478B7" # ECO
)

# Mint tokens to the first recipient
echo "Minting tokens to $RECIPIENT1..."
for TOKEN in "${TOKEN_ADDRESSES[@]}"; do
    echo "Minting from contract $TOKEN..."
    # Encode the function call: mintTo(address,uint256)
    # We need to pad the address and amount to 32 bytes each
    CALLDATA="${MINT_SELECTOR}000000000000000000000000${RECIPIENT1:2}$( printf '%064x' $AMOUNT )"
    
    # Execute the call
    cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $TOKEN $CALLDATA
    
    # Check result
    if [ $? -eq 0 ]; then
        echo "Successfully minted tokens from $TOKEN to $RECIPIENT1"
    else
        echo "Failed to mint tokens from $TOKEN to $RECIPIENT1"
    fi
    
    # Optional: Add a small delay between transactions
    sleep 0.5
done

# Mint tokens to the second recipient
echo "Minting tokens to $RECIPIENT2..."
for TOKEN in "${TOKEN_ADDRESSES[@]}"; do
    echo "Minting from contract $TOKEN..."
    # Encode the function call: mintTo(address,uint256)
    CALLDATA="${MINT_SELECTOR}000000000000000000000000${RECIPIENT2:2}$( printf '%064x' $AMOUNT )"
    
    # Execute the call
    cast send --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 $TOKEN $CALLDATA
    
    # Check result
    if [ $? -eq 0 ]; then
        echo "Successfully minted tokens from $TOKEN to $RECIPIENT2"
    else
        echo "Failed to mint tokens from $TOKEN to $RECIPIENT2"
    fi
    
    # Optional: Add a small delay between transactions
    sleep 0.5
done

echo "All token minting completed!"