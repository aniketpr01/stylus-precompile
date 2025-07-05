//! Poseidon Hash implementation for zero-knowledge proof systems

pub mod constants;
pub mod core;
pub mod interface;

// Re-export the main components
pub use constants::POSEIDON_ROUND_CONSTANTS;
pub use core::{PoseidonHash, PoseidonParams};
pub use interface::{poseidon_precompile, IPoseidonHash};
