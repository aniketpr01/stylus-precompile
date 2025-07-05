#!/bin/bash

# Deployment script for Stylus precompile
# Handles deployment to Arbitrum networks

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source versions
source "$SCRIPT_DIR/versions.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NETWORK="arbitrum-sepolia"
PRIVATE_KEY=""
RPC_URL=""
WASM_FILE="target/wasm32-unknown-unknown/release/precompile.wasm"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -n, --network NETWORK     Target network (default: arbitrum-sepolia)"
    echo "  -k, --private-key KEY     Private key for deployment"
    echo "  -r, --rpc-url URL         RPC endpoint URL"
    echo "  -w, --wasm-file FILE      WASM file path (default: $WASM_FILE)"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --network arbitrum-sepolia --private-key 0x123..."
    echo "  $0 --network arbitrum-mainnet --rpc-url https://arb1.arbitrum.io/rpc"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--network)
            NETWORK="$2"
            shift 2
            ;;
        -k|--private-key)
            PRIVATE_KEY="$2"
            shift 2
            ;;
        -r|--rpc-url)
            RPC_URL="$2"
            shift 2
            ;;
        -w|--wasm-file)
            WASM_FILE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

echo -e "${BLUE}🚀 Deploying Poseidon Hash Precompile to $NETWORK${NC}"

# Change to project root
cd "$PROJECT_ROOT"

# Check if WASM file exists
if [ ! -f "$WASM_FILE" ]; then
    echo -e "${RED}❌ WASM file not found: $WASM_FILE${NC}"
    echo "Please run ./scripts/build.sh first"
    exit 1
fi

# Validate inputs
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}❌ Private key is required${NC}"
    echo "Use --private-key or set PRIVATE_KEY environment variable"
    exit 1
fi

# Check if Stylus CLI is available
if ! command -v cargo-stylus &> /dev/null; then
    echo -e "${YELLOW}⚠️  Stylus CLI not found. Installing...${NC}"
    cargo install cargo-stylus
fi

# Build deployment command
DEPLOY_CMD="cargo stylus deploy"
DEPLOY_CMD="$DEPLOY_CMD --private-key $PRIVATE_KEY"

if [ -n "$RPC_URL" ]; then
    DEPLOY_CMD="$DEPLOY_CMD --endpoint $RPC_URL"
fi

# Show deployment info
echo -e "${YELLOW}📋 Deployment Configuration:${NC}"
echo "  Network: $NETWORK"
echo "  WASM file: $WASM_FILE"
echo "  File size: $(ls -lh "$WASM_FILE" | awk '{print $5}')"
if [ -n "$RPC_URL" ]; then
    echo "  RPC URL: $RPC_URL"
fi

# Confirm deployment
echo -e "${YELLOW}⚠️  This will deploy the precompile to $NETWORK${NC}"
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Execute deployment
echo -e "${BLUE}🚀 Deploying...${NC}"
eval $DEPLOY_CMD

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Deployment successful!${NC}"
    echo -e "${GREEN}🎉 Poseidon Hash Precompile is now live on $NETWORK${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi