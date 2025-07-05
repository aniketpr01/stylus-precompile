#!/bin/bash

# Build script for Poseidon Hash Precompile
# Inspired by Avalanche's build automation

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
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Building Poseidon Hash Precompile${NC}"
echo "Project Root: $PROJECT_ROOT"

# Change to project root
cd "$PROJECT_ROOT"

# Check Rust toolchain
echo -e "${YELLOW}📋 Checking Rust toolchain...${NC}"
if ! rustc --version | grep -q "$RUST_VERSION"; then
    echo -e "${RED}❌ Expected Rust version $RUST_VERSION not found${NC}"
    echo "Current version: $(rustc --version)"
    echo "Please install the correct version with: rustup install $RUST_VERSION"
    exit 1
fi

# Check WASM target
echo -e "${YELLOW}📋 Checking WASM target...${NC}"
if ! rustup target list --installed | grep -q "$WASM_TARGET"; then
    echo -e "${YELLOW}⚠️  WASM target not installed. Installing...${NC}"
    rustup target add "$WASM_TARGET"
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
cargo clean

# Run tests first
echo -e "${YELLOW}🧪 Running tests...${NC}"
cargo test

# Build for native target (development)
echo -e "${YELLOW}🔨 Building native target...${NC}"
cargo build

# Build for WASM target (Stylus deployment)
echo -e "${YELLOW}🕸️  Building WASM target for Stylus...${NC}"
cargo build --target "$WASM_TARGET" --release

# Check if WASM file was created
WASM_FILE="target/$WASM_TARGET/release/precompile.wasm"
if [ -f "$WASM_FILE" ]; then
    echo -e "${GREEN}✅ WASM build successful!${NC}"
    echo "WASM file: $WASM_FILE"
    echo "Size: $(ls -lh "$WASM_FILE" | awk '{print $5}')"
else
    echo -e "${RED}❌ WASM build failed - file not found${NC}"
    exit 1
fi

# Run clippy for linting
echo -e "${YELLOW}🔍 Running Clippy...${NC}"
cargo clippy -- -D warnings

# Format check
echo -e "${YELLOW}📐 Checking code formatting...${NC}"
cargo fmt --check

echo -e "${GREEN}🎉 Build completed successfully!${NC}"
echo -e "${GREEN}📦 Ready for Stylus deployment: $WASM_FILE${NC}"