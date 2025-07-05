#!/bin/bash

# Version management for precompile project
# Inspired by Avalanche's version management approach

# Rust toolchain version
RUST_VERSION="1.86.0"

# Cargo and WASM target versions
WASM_TARGET="wasm32-unknown-unknown"

# Alloy versions
ALLOY_PRIMITIVES_VERSION="0.8"
ALLOY_SOL_TYPES_VERSION="0.8"

# Project version
PROJECT_VERSION="0.1.0"

# Stylus CLI version (if applicable)
STYLUS_CLI_VERSION="latest"

# Export versions for use in other scripts
export RUST_VERSION
export WASM_TARGET
export ALLOY_PRIMITIVES_VERSION
export ALLOY_SOL_TYPES_VERSION
export PROJECT_VERSION
export STYLUS_CLI_VERSION

echo "Loaded versions:"
echo "  Rust: $RUST_VERSION"
echo "  WASM Target: $WASM_TARGET"
echo "  Alloy Primitives: $ALLOY_PRIMITIVES_VERSION"
echo "  Alloy Sol Types: $ALLOY_SOL_TYPES_VERSION"
echo "  Project: $PROJECT_VERSION"
echo "  Stylus CLI: $STYLUS_CLI_VERSION"