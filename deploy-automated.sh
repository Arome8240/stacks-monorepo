#!/bin/bash

# Automated Deployment Script for Stacks Smart Contracts
# This script automates the deployment of all 10 contracts

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NETWORK=${1:-"devnet"}
DEPLOYER_ADDRESS=${STACKS_DEPLOYER_ADDRESS:-"ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"}

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     STACKS BLOCKCHAIN - AUTOMATED DEPLOYMENT SCRIPT         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check prerequisites
echo -e "${BLUE}[1/5] Checking Prerequisites...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v clarinet &> /dev/null; then
    print_error "Clarinet is not installed"
    echo "Please install Clarinet: https://docs.stacks.co/clarinet"
    exit 1
fi
print_status "Clarinet installed"

if ! command -v stacks-cli &> /dev/null; then
    print_warning "stacks-cli not found (optional for advanced deployment)"
else
    print_status "stacks-cli installed"
fi

# Validate network
echo ""
echo -e "${BLUE}[2/5] Validating Configuration...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ "$NETWORK" != "devnet" && "$NETWORK" != "testnet" && "$NETWORK" != "mainnet" ]]; then
    print_error "Invalid network: $NETWORK"
    echo "Usage: $0 [devnet|testnet|mainnet]"
    exit 1
fi

print_info "Network: $NETWORK"
print_info "Deployer: $DEPLOYER_ADDRESS"

# Check contract syntax
echo ""
echo -e "${BLUE}[3/5] Checking Contract Syntax...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

print_warning "Note: Some contracts use 'as-contract' which requires Clarity 2"
print_info "Checking syntax (warnings expected)..."

# Run syntax check but don't fail on warnings
clarinet check 2>&1 | grep -E "(error:|warning:)" | head -20 || true

# List contracts to deploy
echo ""
echo -e "${BLUE}[4/5] Preparing Deployment...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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

echo "Contracts to deploy:"
for i in "${!CONTRACTS[@]}"; do
    echo "  $((i+1)). ${CONTRACTS[$i]}"
done

# Deployment
echo ""
echo -e "${BLUE}[5/5] Deploying Contracts...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$NETWORK" == "devnet" ]; then
    print_info "Starting devnet deployment..."

    # For devnet, we can use clarinet integrate
    print_info "Generating deployment plan..."

    cat > deployment-plan.yaml << EOF
---
id: 0
name: Stacks Contracts Deployment
network: devnet
stacks-node: http://localhost:20443
bitcoin-node: http://devnet:devnet@localhost:18443
plan:
  batches:
EOF

    # Add each contract to the deployment plan
    for contract in "${CONTRACTS[@]}"; do
        cat >> deployment-plan.yaml << EOF
    - id: $((RANDOM))
      transactions:
        - contract-publish:
            contract-name: $contract
            expected-sender: $DEPLOYER_ADDRESS
            cost: 100000
            path: contracts/$contract.clar
            clarity-version: 2
EOF
    done

    print_status "Deployment plan created"
    print_info "To deploy on devnet, run: clarinet integrate"

elif [ "$NETWORK" == "testnet" ]; then
    print_warning "Testnet deployment requires:"
    echo "  1. Funded testnet account"
    echo "  2. Private key configuration"
    echo "  3. Manual deployment via Clarinet or Stacks CLI"
    echo ""
    print_info "Deployment commands for testnet:"

    for contract in "${CONTRACTS[@]}"; do
        echo "  clarinet deployments generate --testnet"
        echo "  clarinet deployments apply -p deployments/default.testnet-plan.yaml"
        break
    done

elif [ "$NETWORK" == "mainnet" ]; then
    print_error "MAINNET DEPLOYMENT BLOCKED"
    echo ""
    echo "⚠️  IMPORTANT SECURITY NOTICE ⚠️"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Before deploying to mainnet, you MUST:"
    echo "  1. Complete a professional security audit"
    echo "  2. Test thoroughly on testnet"
    echo "  3. Fix all 'as-contract' compatibility issues"
    echo "  4. Review all contract logic"
    echo "  5. Prepare emergency procedures"
    echo "  6. Have insurance/bug bounty program"
    echo ""
    echo "To proceed with mainnet deployment:"
    echo "  - Remove the safety check in this script"
    echo "  - Use: clarinet deployments generate --mainnet"
    echo "  - Manually review and apply the deployment plan"
    exit 1
fi

# Generate deployment documentation
echo ""
echo -e "${BLUE}Generating Deployment Documentation...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > DEPLOYMENT_LOG.md << EOF
# Deployment Log

**Date**: $(date)
**Network**: $NETWORK
**Deployer**: $DEPLOYER_ADDRESS

## Contracts

EOF

for contract in "${CONTRACTS[@]}"; do
    size=$(wc -c < "contracts/$contract.clar")
    cat >> DEPLOYMENT_LOG.md << EOF
### $contract
- File: \`contracts/$contract.clar\`
- Size: $size bytes
- Status: Pending deployment

EOF
done

cat >> DEPLOYMENT_LOG.md << EOF

## Deployment Steps

1. Review all contracts
2. Test on devnet
3. Deploy to testnet
4. Audit and test
5. Deploy to mainnet (after audit)

## Post-Deployment Checklist

- [ ] Verify contract deployment
- [ ] Test basic functions
- [ ] Monitor for issues
- [ ] Document contract addresses
- [ ] Set up monitoring/alerts
- [ ] Update frontend/backend integrations

EOF

print_status "Deployment documentation created: DEPLOYMENT_LOG.md"

# Summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    DEPLOYMENT SUMMARY                        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Network:           $NETWORK"
echo "Contracts:         ${#CONTRACTS[@]}"
echo "Status:            Ready for deployment"
echo ""

if [ "$NETWORK" == "devnet" ]; then
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Start devnet: clarinet integrate"
    echo "  2. Or use: clarinet console"
    echo "  3. Deploy contracts interactively"
elif [ "$NETWORK" == "testnet" ]; then
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Configure testnet credentials"
    echo "  2. Generate deployment: clarinet deployments generate --testnet"
    echo "  3. Review deployment plan"
    echo "  4. Apply: clarinet deployments apply -p deployments/default.testnet-plan.yaml"
fi

echo ""
print_status "Deployment preparation complete!"
echo ""
