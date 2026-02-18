#!/bin/bash

# Deployment script for Stacks smarttracts

echo "🚀 Starting deployment process..."

# Check if network is specified
if [ -z "$1" ]; then
    echo "❌ Error: Network not specified"
    echo "Usage: ./deploy.sh [testnet|mainnet]"
    exit 1
fi

NETWORK=$1

echo "📡 Deploying to $NETWORK..."

# Deploy contracts in order
echo "1️⃣  Deploying Lottery System..."
clarinet deploy --$NETWORK contracts/lottery-system.clar

echo "2️⃣  Deploying NFT Marketplace..."
clarinet deploy --$NETWORK contracts/nft-marketplace.clar

echo "3️⃣  Deploying Time-Locked Vault..."
clarinet deploy --$NETWORK contracts/time-locked-vault.clar

echo "4️⃣  Deploying Multi-Sig Wallet..."
clarinet deploy --$NETWORK contracts/multi-sig-wallet.clar

echo "5️⃣  Deploying Crowdfunding..."
clarinet deploy --$NETWORK contracts/crowdfunding.clar

echo "6️⃣  Deploying DAO Governance..."
clarinet deploy --$NETWORK contracts/dao-governance.clar

echo "7️⃣  Deploying Escrow Service..."
clarinet deploy --$NETWORK contracts/escrow-service.clar

echo "8️⃣  Deploying Oracle Feed..."
clarinet deploy --$NETWORK contracts/oracle-feed.clar

echo "9️⃣  Deploying Staking Pool..."
clarinet deploy --$NETWORK contracts/staking-pool.clar

echo "🔟 Deploying Token Vault..."
clarinet deploy --$NETWORK contracts/token-vault.clar

echo "✅ All contracts deployed successfully!"
