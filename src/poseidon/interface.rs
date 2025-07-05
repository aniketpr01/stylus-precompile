//! Poseidon precompile interface and ABI definitions

use super::core::PoseidonHash;
use crate::errors::PoseidonError;
use alloy_sol_types::{sol, SolCall, SolValue};

// Solidity interface definition
sol! {
    interface IPoseidonHash {
        /// Computes Poseidon hash of a single field element
        /// @param input The field element to hash
        /// @return hash The resulting Poseidon hash
        function poseidon1(uint256 input) external pure returns (uint256 hash);

        /// Computes Poseidon hash of two field elements
        /// @param left The left field element
        /// @param right The right field element
        /// @return hash The resulting Poseidon hash
        function poseidon2(uint256 left, uint256 right) external pure returns (uint256 hash);

        /// Computes Poseidon hash of an array of field elements
        /// @param inputs Array of field elements to hash
        /// @return hash The resulting Poseidon hash
        function poseidonN(uint256[] inputs) external pure returns (uint256 hash);
    }
}

/// Precompile entry point - handles the raw call interface
pub fn poseidon_precompile(input: &[u8]) -> Result<Vec<u8>, PoseidonError> {
    if input.len() < 4 {
        return Err(PoseidonError::InvalidSelector);
    }

    let selector = &input[0..4];
    let call_data = &input[4..];

    let hasher = PoseidonHash::new();

    match selector {
        // poseidon1(uint256)
        s if s == IPoseidonHash::poseidon1Call::SELECTOR => {
            let decoded = IPoseidonHash::poseidon1Call::abi_decode(call_data, true)
                .map_err(|e| PoseidonError::AbiDecodeError(e.to_string()))?;

            let hash = hasher.hash_single(decoded.input)?;
            Ok(hash.abi_encode())
        }

        // poseidon2(uint256,uint256)
        s if s == IPoseidonHash::poseidon2Call::SELECTOR => {
            let decoded = IPoseidonHash::poseidon2Call::abi_decode(call_data, true)
                .map_err(|e| PoseidonError::AbiDecodeError(e.to_string()))?;

            let hash = hasher.hash_pair(decoded.left, decoded.right)?;
            Ok(hash.abi_encode())
        }

        // poseidonN(uint256[])
        s if s == IPoseidonHash::poseidonNCall::SELECTOR => {
            let decoded = IPoseidonHash::poseidonNCall::abi_decode(call_data, true)
                .map_err(|e| PoseidonError::AbiDecodeError(e.to_string()))?;

            let hash = hasher.hash_array(&decoded.inputs)?;
            Ok(hash.abi_encode())
        }

        _ => Err(PoseidonError::InvalidSelector),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use alloy_primitives::U256;

    #[test]
    fn test_precompile_interface() {
        // Test poseidon1
        let input = U256::from(42);
        let call_data = IPoseidonHash::poseidon1Call { input }.abi_encode();
        let mut full_input = IPoseidonHash::poseidon1Call::SELECTOR.to_vec();
        full_input.extend_from_slice(&call_data);

        let result = poseidon_precompile(&full_input);
        assert!(result.is_ok());

        let output = result.unwrap();
        assert_eq!(output.len(), 32); // U256 is 32 bytes
    }
}
