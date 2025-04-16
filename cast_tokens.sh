#!/bin/bash

# Store the bytecode once
BYTECODE="0x608080604052600436101561001357600080fd5b60003560e01c90816306fdde031461056257508063095ea7b31461053c57806318160ddd1461051e57806323b872dd1461045f578063313ce5671461044357806339509351146103f1578063449a52f81461032c57806370a08231146102f257806395d89b41146101d1578063a457c2d71461012a578063a9059cbb146100f95763dd62ed3e146100a357600080fd5b346100f45760403660031901126100f4576100bc61067e565b6100c4610694565b6001600160a01b039182166000908152600160209081526040808320949093168252928352819020549051908152f35b600080fd5b346100f45760403660031901126100f45761011f61011561067e565b60243590336107d5565b602060405160018152f35b346100f45760403660031901126100f45761014361067e565b60243590336000526001602052604060002060018060a01b0382166000526020526040600020549180831061017e5761011f920390336106cd565b60405162461bcd60e51b815260206004820152602560248201527f45524332303a2064656372656173656420616c6c6f77616e63652062656c6f77604482015264207a65726f60d81b6064820152608490fd5b346100f45760003660031901126100f45760405160006004548060011c906001811680156102e8575b6020831081146102d4578285529081156102b85750600114610261575b50819003601f01601f191681019067ffffffffffffffff82118183101761024b5761024782918260405282610635565b0390f35b634e487b7160e01b600052604160045260246000fd5b905060046000527f8a35acfbc15ff81a39ae7d344fd709f28e8600b4aa8c65c6b64bfe7fe36bd19b6000905b8282106102a257506020915082010182610217565b600181602092548385880101520191019061028d565b90506020925060ff191682840152151560051b82010182610217565b634e487b7160e01b84526022600452602484fd5b91607f16916101fa565b346100f45760203660031901126100f4576001600160a01b0361031361067e565b1660005260006020526020604060002054604051908152f35b346100f45760403660031901126100f45761034561067e565b6001600160a01b031660243581156103ac577fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef6020826103896000946002546106aa565b600255848452838252604084206103a18282546106aa565b9055604051908152a3005b60405162461bcd60e51b815260206004820152601f60248201527f45524332303a206d696e7420746f20746865207a65726f2061646472657373006044820152606490fd5b346100f45760403660031901126100f45761011f61040d61067e565b336000526001602052604060002060018060a01b03821660005260205261043c604060002060243590546106aa565b90336106cd565b346100f45760003660031901126100f457602060405160128152f35b346100f45760603660031901126100f45761047861067e565b610480610694565b9061048f6044358093836107d5565b6001600160a01b0381166000908152600160209081526040808320338452909152902054918083106104c85761011f92039033906106cd565b60405162461bcd60e51b815260206004820152602860248201527f45524332303a207472616e7366657220616d6f756e74206578636565647320616044820152676c6c6f77616e636560c01b6064820152608490fd5b346100f45760003660031901126100f4576020600254604051908152f35b346100f45760403660031901126100f45761011f61055861067e565b60243590336106cd565b346100f45760003660031901126100f45760006003548060011c9060018116801561062b575b6020831081146102d4578285529081156102b857506001146105d45750819003601f01601f191681019067ffffffffffffffff82118183101761024b5761024782918260405282610635565b905060036000527fc2575a0e9e593c00f959f8c92f12db2869c3395a3b0502d05e2516446f71f85b6000905b82821061061557506020915082010182610217565b6001816020925483858801015201910190610600565b91607f1691610588565b91909160208152825180602083015260005b818110610668575060409293506000838284010152601f8019910116010190565b8060208092870101516040828601015201610647565b600435906001600160a01b03821682036100f457565b602435906001600160a01b03821682036100f457565b919082018092116106b757565b634e487b7160e01b600052601160045260246000fd5b6001600160a01b0316908115610784576001600160a01b03169182156107345760207f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925918360005260018252604060002085600052825280604060002055604051908152a3565b60405162461bcd60e51b815260206004820152602260248201527f45524332303a20617070726f766520746f20746865207a65726f206164647265604482015261737360f01b6064820152608490fd5b60405162461bcd60e51b8152602060048201526024808201527f45524332303a20617070726f76652066726f6d20746865207a65726f206164646044820152637265737360e01b6064820152608490fd5b6001600160a01b0316908115610908576001600160a01b03169182156108b75781600052600060205260406000205481811061086357817fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef92602092856000526000845203604060002055846000526000825260406000206108588282546106aa565b9055604051908152a3565b60405162461bcd60e51b815260206004820152602660248201527f45524332303a207472616e7366657220616d6f756e7420657863656564732062604482015265616c616e636560d01b6064820152608490fd5b60405162461bcd60e51b815260206004820152602360248201527f45524332303a207472616e7366657220746f20746865207a65726f206164647260448201526265737360e81b6064820152608490fd5b60405162461bcd60e51b815260206004820152602560248201527f45524332303a207472616e736665722066726f6d20746865207a65726f206164604482015264647265737360d81b6064820152608490fdfea264697066735822122002e992ff9b70223ac3a856e80df278adde6bd698f33976bfc1ecebf9f08a676064736f6c634300081a0033"

# Define all the addresses as an array
declare -a ADDRESSES=(
    "0xb1e25689D55734FD3ffFc939c4C3Eb52DFf8A794" # OS 70k
    "0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE" # SCUSD 84k
    "0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812" # SCETH 53.9k
    "0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd" # SCBTC 53.9k
    "0xE5DA20F15420aD15DE0fa650600aFc998bbE3955" # STS 24.5k
    "0x3333b97138D4b086720b5aE8A7844b1345a33333" # SHADOW 24.5k
    "0x3333111A391cC08fa51353E9195526A70b333333" # X33 19.6k
    "0x7A0C53F7eb34C5BC8B01691723669adA9D6CB384" # BOO 19.6k
    "0xddF26B42C1d903De8962d3F79a74a501420d5F19" # EQUAL 19.6k
    "0xf26Ff70573ddc8a90Bd7865AF8d7d70B8Ff019bC" # EGGS 17.5k
    "0x79bbF4508B1391af3A0F4B30bb5FC4aa9ab0E07C" # ANON 10.5k
    "0xe920d1DA9A4D59126dC35996Ea242d60EFca1304" # DERP 8.05k
    "0x9fDbC3f8Abc05Fa8f3Ad3C17D2F806c1230c4564" # GOGLZ 7k
    "0x6fB9897896Fe5D05025Eb43306675727887D0B7c" # HEDGY 7k
    "0x31E2eed04a62b232DA964A097D8C171584e3C3Bd" # OIL 9.1k
    "0xf4F9C50455C698834Bb645089DbAa89093b93838" # TOONA 7k
    "0xE51EE9868C1f0d6cd968A8B8C8376Dc2991BFE44" # BRUSH 7k
    "0x7A08Bf5304094CA4C7b4132Ef62b5EDc4a3478B7" # ECO 4.9k
)

# Loop through all addresses and deploy the contract to each
for ADDRESS in "${ADDRESSES[@]}"; do
    echo "Deploying contract to $ADDRESS..."
    cast rpc anvil_setCode "$ADDRESS" "$BYTECODE"
    
    # Optional: Check the deployment result
    RESULT=$?
    if [ $RESULT -eq 0 ]; then
        echo "Successfully deployed to $ADDRESS"
    else
        echo "Failed to deploy to $ADDRESS"
    fi
    
    # Optional: Add a small delay between deployments if needed
    sleep 0.5
done

echo "All contracts deployed!"