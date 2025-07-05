//! Precompile framework for Arbitrum Stylus
//! 
//! This library provides a framework for developing precompiles on Arbitrum Stylus,
//! with a focus on cryptographic operations and gas optimization.

#![cfg_attr(not(feature = "std"), no_std)]

// Re-export common types and traits
pub use alloy_primitives::{Address, Bytes, U256};
pub use alloy_sol_types::{sol, SolCall, SolValue};

// Core modules
pub mod errors;
pub mod utils;

// Precompile implementations
pub mod poseidon;

// Re-export precompile interfaces for convenience
pub use poseidon::{
    poseidon_precompile, PoseidonHash, IPoseidonHash, POSEIDON_ROUND_CONSTANTS
};

// CLI module (only available with cli feature)
#[cfg(feature = "cli")]
pub mod cli;

// Export the entrypoint for Stylus deployment
#[cfg(feature = "stylus")]
pub mod entrypoint;

// Common prelude for users of this library
pub mod prelude {
    pub use crate::errors::*;
    pub use crate::utils::*;
    pub use alloy_primitives::{Address, Bytes, U256};
    pub use alloy_sol_types::{sol, SolCall, SolValue};
}