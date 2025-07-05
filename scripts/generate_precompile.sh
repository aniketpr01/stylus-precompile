#!/bin/bash

# Precompile generation script inspired by Avalanche's approach
# Creates scaffolding for new precompiles

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PRECOMPILE_NAME=""
OUTPUT_DIR="$PROJECT_ROOT/src"

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS] PRECOMPILE_NAME"
    echo ""
    echo "Generate scaffolding for a new precompile"
    echo ""
    echo "Arguments:"
    echo "  PRECOMPILE_NAME          Name of the precompile (e.g., 'sha256', 'blake2b')"
    echo ""
    echo "Options:"
    echo "  -o, --output-dir DIR     Output directory (default: src/)"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 sha256"
    echo "  $0 blake2b --output-dir ./custom-precompiles"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            if [ -z "$PRECOMPILE_NAME" ]; then
                PRECOMPILE_NAME="$1"
            else
                echo "Multiple precompile names provided"
                usage
            fi
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$PRECOMPILE_NAME" ]; then
    echo -e "${RED}❌ Precompile name is required${NC}"
    usage
fi

# Validate precompile name format
if [[ ! "$PRECOMPILE_NAME" =~ ^[a-zA-Z0-9_]+$ ]]; then
    echo -e "${RED}❌ Invalid precompile name. Use only letters, numbers, and underscores${NC}"
    exit 1
fi

echo -e "${BLUE}🏗️  Generating precompile: ${PRECOMPILE_NAME}${NC}"

# Convert to different case formats
PRECOMPILE_LOWER=$(echo "$PRECOMPILE_NAME" | tr '[:upper:]' '[:lower:]')
PRECOMPILE_UPPER=$(echo "$PRECOMPILE_NAME" | tr '[:lower:]' '[:upper:]')
PRECOMPILE_PASCAL=$(echo "$PRECOMPILE_NAME" | sed 's/^./\U&/')

# Create output directory
PRECOMPILE_DIR="$OUTPUT_DIR/$PRECOMPILE_LOWER"
mkdir -p "$PRECOMPILE_DIR"

echo -e "${YELLOW}📁 Creating directory structure...${NC}"
echo "  Output directory: $PRECOMPILE_DIR"

# Generate module files
echo -e "${YELLOW}📄 Generating module files...${NC}"

# mod.rs
cat > "$PRECOMPILE_DIR/mod.rs" << EOF
//! ${PRECOMPILE_PASCAL} Precompile Module
//!
//! This module implements a ${PRECOMPILE_PASCAL} precompile for Arbitrum Stylus.

pub mod core;
pub mod interface;
pub mod params;

// Re-export main types and functions
pub use core::${PRECOMPILE_PASCAL};
pub use interface::{${PRECOMPILE_LOWER}_precompile, I${PRECOMPILE_PASCAL}};
pub use params::${PRECOMPILE_UPPER}_PARAMS;
EOF

# params.rs
cat > "$PRECOMPILE_DIR/params.rs" << EOF
use alloy_primitives::U256;

/// Parameters for ${PRECOMPILE_PASCAL} precompile
pub struct ${PRECOMPILE_PASCAL}Params {
    // Add your parameters here
    pub example_param: U256,
}

impl Default for ${PRECOMPILE_PASCAL}Params {
    fn default() -> Self {
        Self {
            example_param: U256::from(42),
        }
    }
}

/// Default parameters for ${PRECOMPILE_PASCAL}
pub const ${PRECOMPILE_UPPER}_PARAMS: ${PRECOMPILE_PASCAL}Params = ${PRECOMPILE_PASCAL}Params {
    example_param: U256::from_limbs([42, 0, 0, 0]),
};
EOF

# core.rs
cat > "$PRECOMPILE_DIR/core.rs" << EOF
use alloy_primitives::U256;
use crate::errors::PoseidonError; // TODO: Create ${PRECOMPILE_PASCAL}Error
use super::params::${PRECOMPILE_PASCAL}Params;

/// ${PRECOMPILE_PASCAL} implementation
pub struct ${PRECOMPILE_PASCAL} {
    params: ${PRECOMPILE_PASCAL}Params,
}

impl Default for ${PRECOMPILE_PASCAL} {
    fn default() -> Self {
        Self::new()
    }
}

impl ${PRECOMPILE_PASCAL} {
    /// Creates a new ${PRECOMPILE_PASCAL} instance with default parameters
    pub fn new() -> Self {
        Self {
            params: ${PRECOMPILE_PASCAL}Params::default(),
        }
    }

    /// Main computation function
    pub fn compute(&self, input: &[u8]) -> Result<Vec<u8>, PoseidonError> {
        // TODO: Implement your ${PRECOMPILE_PASCAL} logic here
        todo!("Implement ${PRECOMPILE_PASCAL} computation")
    }

    /// Validate input data
    fn validate_input(&self, input: &[u8]) -> Result<(), PoseidonError> {
        if input.is_empty() {
            return Err(PoseidonError::InvalidInputLength(0));
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_${PRECOMPILE_LOWER}_creation() {
        let ${PRECOMPILE_LOWER} = ${PRECOMPILE_PASCAL}::new();
        // Add your tests here
    }

    #[test]
    fn test_${PRECOMPILE_LOWER}_compute() {
        let ${PRECOMPILE_LOWER} = ${PRECOMPILE_PASCAL}::new();
        // TODO: Add computation tests
    }
}
EOF

# interface.rs
cat > "$PRECOMPILE_DIR/interface.rs" << EOF
use alloy_sol_types::{sol, SolCall, SolValue};
use crate::errors::PoseidonError; // TODO: Create ${PRECOMPILE_PASCAL}Error
use super::core::${PRECOMPILE_PASCAL};

// Solidity interface definition
sol! {
    interface I${PRECOMPILE_PASCAL} {
        /// Main function for ${PRECOMPILE_PASCAL} computation
        /// @param input The input data
        /// @return output The computed result
        function ${PRECOMPILE_LOWER}(bytes input) external pure returns (bytes output);
    }
}

/// Precompile entry point - handles the raw call interface
pub fn ${PRECOMPILE_LOWER}_precompile(input: &[u8]) -> Result<Vec<u8>, PoseidonError> {
    if input.len() < 4 {
        return Err(PoseidonError::InvalidSelector);
    }

    let selector = &input[0..4];
    let call_data = &input[4..];

    let processor = ${PRECOMPILE_PASCAL}::new();

    match selector {
        // ${PRECOMPILE_LOWER}(bytes)
        s if s == I${PRECOMPILE_PASCAL}::${PRECOMPILE_LOWER}Call::SELECTOR => {
            let decoded = I${PRECOMPILE_PASCAL}::${PRECOMPILE_LOWER}Call::abi_decode(call_data, true)
                .map_err(|e| PoseidonError::AbiDecodeError(e.to_string()))?;

            let result = processor.compute(&decoded.input)?;
            Ok(result)
        }

        _ => Err(PoseidonError::InvalidSelector),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_${PRECOMPILE_LOWER}_interface() {
        // TODO: Add interface tests
    }
}
EOF

# Generate Solidity interface
echo -e "${YELLOW}📄 Generating Solidity interface...${NC}"
SOLIDITY_DIR="$PROJECT_ROOT/contracts/interfaces"
mkdir -p "$SOLIDITY_DIR"

cat > "$SOLIDITY_DIR/I${PRECOMPILE_PASCAL}.sol" << EOF
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title I${PRECOMPILE_PASCAL}
 * @dev Interface for ${PRECOMPILE_PASCAL} precompile
 * @notice TODO: Add description for ${PRECOMPILE_PASCAL} functionality
 */
interface I${PRECOMPILE_PASCAL} {
    /**
     * @dev Main ${PRECOMPILE_PASCAL} computation function
     * @param input The input data for ${PRECOMPILE_PASCAL}
     * @return output The computed result
     */
    function ${PRECOMPILE_LOWER}(bytes calldata input) external pure returns (bytes memory output);
}

/**
 * @title ${PRECOMPILE_PASCAL}Precompile
 * @dev Wrapper contract for the ${PRECOMPILE_PASCAL} precompile
 */
contract ${PRECOMPILE_PASCAL}Precompile {
    /// @dev Address where the ${PRECOMPILE_PASCAL} precompile is deployed
    address public constant ${PRECOMPILE_UPPER}_PRECOMPILE = address(0x100); // TODO: Update address

    /**
     * @dev Calls the ${PRECOMPILE_PASCAL} precompile
     */
    function ${PRECOMPILE_LOWER}(bytes calldata input) external pure returns (bytes memory output) {
        (bool success, bytes memory result) = ${PRECOMPILE_UPPER}_PRECOMPILE.staticcall(
            abi.encodeWithSelector(I${PRECOMPILE_PASCAL}.${PRECOMPILE_LOWER}.selector, input)
        );

        require(success, "${PRECOMPILE_PASCAL} precompile call failed");
        return abi.decode(result, (bytes));
    }
}
EOF

# Generate test file
echo -e "${YELLOW}📄 Generating test file...${NC}"
TEST_DIR="$PROJECT_ROOT/tests"
mkdir -p "$TEST_DIR"

cat > "$TEST_DIR/${PRECOMPILE_LOWER}_tests.rs" << EOF
//! Tests for ${PRECOMPILE_PASCAL} precompile

use precompile::*;

#[cfg(test)]
mod ${PRECOMPILE_LOWER}_tests {
    use super::*;

    #[test]
    fn test_${PRECOMPILE_LOWER}_basic() {
        // TODO: Add basic functionality tests
    }

    #[test]
    fn test_${PRECOMPILE_LOWER}_edge_cases() {
        // TODO: Add edge case tests
    }
}
EOF

# Update main lib.rs to include the new module
echo -e "${YELLOW}📝 Updating lib.rs...${NC}"
LIB_FILE="$PROJECT_ROOT/src/lib.rs"

# Check if module already declared
if ! grep -q "pub mod ${PRECOMPILE_LOWER};" "$LIB_FILE"; then
    # Add module declaration after the existing modules
    sed -i.bak "/pub mod poseidon;/a\\
pub mod ${PRECOMPILE_LOWER};
" "$LIB_FILE"
    
    # Add re-export
    sed -i.bak "/pub use poseidon::/a\\
pub use ${PRECOMPILE_LOWER}::{${PRECOMPILE_LOWER}_precompile, I${PRECOMPILE_PASCAL}, ${PRECOMPILE_PASCAL}};
" "$LIB_FILE"
    
    # Remove backup file
    rm -f "$LIB_FILE.bak"
    
    echo -e "${GREEN}✅ Updated lib.rs${NC}"
else
    echo -e "${YELLOW}⚠️  Module already declared in lib.rs${NC}"
fi

echo -e "${GREEN}🎉 Successfully generated ${PRECOMPILE_PASCAL} precompile!${NC}"
echo ""
echo -e "${BLUE}📁 Generated files:${NC}"
echo "  📂 $PRECOMPILE_DIR/"
echo "    📄 mod.rs"
echo "    📄 core.rs"
echo "    📄 interface.rs"
echo "    📄 params.rs"
echo "  📄 $SOLIDITY_DIR/I${PRECOMPILE_PASCAL}.sol"
echo "  📄 $TEST_DIR/${PRECOMPILE_LOWER}_tests.rs"
echo ""
echo -e "${YELLOW}📋 Next steps:${NC}"
echo "  1. Implement the core logic in ${PRECOMPILE_LOWER}/core.rs"
echo "  2. Define proper parameters in ${PRECOMPILE_LOWER}/params.rs"
echo "  3. Add comprehensive tests in tests/${PRECOMPILE_LOWER}_tests.rs"
echo "  4. Update the Solidity interface as needed"
echo "  5. Create custom error types if needed"
echo "  6. Build and test: ./scripts/build.sh"
EOF