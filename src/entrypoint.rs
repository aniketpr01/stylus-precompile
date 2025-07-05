#![cfg_attr(not(feature = "std"), no_std)]
extern crate alloc;

use alloy_primitives::U256;
use stylus_sdk::prelude::*;

// For Stylus deployment, we create a simple router contract
sol_storage! {
    #[entrypoint]
    pub struct PoseidonPrecompile {
    }
}

#[public]
impl PoseidonPrecompile {
    // Simple Poseidon hash of a single U256
    pub fn hash(&self, input: U256) -> U256 {
        use crate::poseidon::PoseidonHash;

        let hasher = PoseidonHash::new();
        match hasher.hash_single(input) {
            Ok(result) => result,
            Err(_) => U256::ZERO, // Return zero on error for simplicity
        }
    }

    // Hash two U256 values
    pub fn hash_pair(&self, a: U256, b: U256) -> U256 {
        use crate::poseidon::PoseidonHash;

        let hasher = PoseidonHash::new();
        match hasher.hash_pair(a, b) {
            Ok(result) => result,
            Err(_) => U256::ZERO,
        }
    }
}
