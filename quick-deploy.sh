#!/bin/bash

# Quick Deploy Script - One-command deployment
# Usage: ./quick-deploy.sh

echo "🚀 Quick Deploy - Stacks Contracts"
echo "=================================="
echo ""

# Check if clarinet is running
if pgrep -x "clarinet" > /dev/null; then
    echo "✓ Clarinet is running"
else
    echo "Starting Clarinet devnet..."
    clarinet integrate &
    sleep 5
fi

# Deploy using the automated script
./deploy-automated.sh devnet

echo ""
echo "📝 Deployment plan created: deployment-plan.yaml"
echo "📄 Deployment log created: DEPLOYMENT_LOG.md"
echo ""
echo "To deploy contracts, run:"
echo "  clarinet integrate"
echo ""
echo "Or test in console:"
echo "  clarinet console"
