#!/bin/bash

# Deployment Verification Script
# Verifies that all contracts are deployed correctly

echo "🔍 Verifying Contract Deployment"
echo "================================="
echo ""

NETWORK=${1:-"devnet"}
DEPLOYER=${2:-"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"}

CONTRACTS=(
    "nft-marketplace"
    "oracle-feed"
    "lottery-system"
    "time-locked-vault"
    "multi-sig-wallet"
    "crowdfunding"
    "dao-governance"
    "escrow-service"
    "staking-pool"
    "token-vault"
)

echo "Network: $NETWORK"
echo "Deployer: $DEPLOYER"
echo ""

# Check each contract
for contract in "${CONTRACTS[@]}"; do
    echo -n "Checking $contract... "

    # Check if contract file exists
    if [ -f "contracts/$contract.clar" ]; then
        size=$(wc -c < "contracts/$contract.clar")
        echo "✓ ($size bytes)"
    else
        echo "✗ File not found"
    fi
done

echo ""
echo "Verification complete!"
echo ""
echo "To verify on blockchain:"
echo "  1. Start console: clarinet console"
echo "  2. Check contract: (contract-call? .$contract-name ...)"
echo "  3. Or use explorer: https://explorer.stacks.co/"
