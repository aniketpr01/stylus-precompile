//! Error types for the precompile library

use alloy_primitives::U256;
use thiserror::Error;

/// Custom error types for the Poseidon precompile
#[derive(Error, Debug)]
pub enum PoseidonError {
    #[error("Invalid input length: expected at least 1 element, got {0}")]
    InvalidInputLength(usize),
    #[error("Field element too large: {0}")]
    FieldElementTooLarge(U256),
    #[error("Invalid function selector")]
    InvalidSelector,
    #[error("ABI decode error: {0}")]
    AbiDecodeError(String),
}
