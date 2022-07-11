#!/bin/bash

cd contracts/circuits

mkdir Multiplier3_PLONK

if [ -f ./powersOfTau28_hez_final_10.ptau ]; then
    echo "powersOfTau28_hez_final_10.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_10.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_10.ptau
fi

echo "Compiling Multiplier3.circom..."

# Compile the circuit

circom Multiplier3.circom --r1cs --wasm --sym -o Multiplier3_PLONK
snarkjs r1cs info Multiplier3_PLONK/Multiplier3.r1cs

echo "Using snarkjs to create zkey..."

# Start a new zkey and make a contribution

snarkjs plonk setup Multiplier3_PLONK/Multiplier3.r1cs powersOfTau28_hez_final_10.ptau Multiplier3_PLONK/circuit_final.zkey
snarkjs zkey export verificationkey Multiplier3_PLONK/circuit_final.zkey Multiplier3_PLONK/verification_key.json

echo "Generating solidity contract..."

# Generate solidity contract
snarkjs zkey export solidityverifier Multiplier3_PLONK/circuit_final.zkey ../Multiplier3PlonkVerifier.sol

cd ../..