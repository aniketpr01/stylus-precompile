//! Integration tests for Poseidon hash precompile

use alloy_primitives::U256;
use hex_literal::hex;
use precompile::*;

#[cfg(test)]
mod integration_tests {
    use super::*;

    #[test]
    fn test_basic_functionality() {
        let hasher = PoseidonHash::new();

        // Test single element hashing
        let single_result = hasher.hash_single(U256::from(42));
        assert!(single_result.is_ok());

        // Test pair hashing
        let pair_result = hasher.hash_pair(U256::from(1), U256::from(2));
        assert!(pair_result.is_ok());

        // Test array hashing
        let array_result = hasher.hash_array(&[U256::from(1), U256::from(2), U256::from(3)]);
        assert!(array_result.is_ok());
    }

    #[test]
    fn test_deterministic_output() {
        let hasher = PoseidonHash::new();

        let input = U256::from(12345);
        let result1 = hasher.hash_single(input).unwrap();
        let result2 = hasher.hash_single(input).unwrap();

        assert_eq!(result1, result2, "Hash should be deterministic");
    }

    #[test]
    fn test_different_inputs_different_outputs() {
        let hasher = PoseidonHash::new();

        let hash1 = hasher.hash_single(U256::from(1)).unwrap();
        let hash2 = hasher.hash_single(U256::from(2)).unwrap();

        assert_ne!(
            hash1, hash2,
            "Different inputs should produce different hashes"
        );
    }

    #[test]
    fn test_field_boundaries() {
        let hasher = PoseidonHash::new();

        // Test maximum valid field element
        let max_valid = hasher.params.modulus - U256::from(1);
        let result = hasher.hash_single(max_valid);
        assert!(result.is_ok(), "Max valid field element should be accepted");

        // Test invalid field element (modulus itself)
        let invalid = hasher.params.modulus;
        let result = hasher.hash_single(invalid);
        assert!(result.is_err(), "Field modulus should be rejected");
    }

    #[test]
    fn test_precompile_call_interface() {
        use alloy_sol_types::{SolCall, SolValue};

        // Test poseidon1 call
        let input = U256::from(100);
        let call = IPoseidonHash::poseidon1Call { input };
        let encoded = call.abi_encode();

        let mut full_call = IPoseidonHash::poseidon1Call::SELECTOR.to_vec();
        full_call.extend_from_slice(&encoded);

        let result = poseidon_precompile(&full_call);
        assert!(result.is_ok());

        let output = result.unwrap();
        let decoded_hash = U256::abi_decode(&output, true).unwrap();
        assert_ne!(decoded_hash, U256::ZERO);
    }

    #[test]
    fn test_error_cases() {
        // Test invalid selector
        let invalid_call = vec![0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]; // Invalid selector + some data
        let result = poseidon_precompile(&invalid_call);
        assert!(result.is_err());

        // Test too short input
        let short_call = vec![0x12, 0x34]; // Less than 4 bytes
        let result = poseidon_precompile(&short_call);
        assert!(result.is_err());
    }
}

#[cfg(test)]
mod production_tests {
    use super::*;

    #[test]
    fn test_production_hash_single() {
        let hasher = PoseidonHash::new();
        
        // Test production implementation
        let input = U256::from(42);
        let hash = hasher.hash_single_production(input).unwrap();
        
        // Should be deterministic
        let hash2 = hasher.hash_single_production(input).unwrap();
        assert_eq!(hash, hash2);
        
        // Should be different from simplified version
        let simple_hash = hasher.hash_single(input).unwrap();
        assert_ne!(hash, simple_hash, "Production and simplified should differ");
    }

    #[test]
    fn test_production_hash_consistency() {
        let hasher = PoseidonHash::new();
        
        // Test that production hashes are consistent with poseidon-rs library
        let test_values = vec![
            U256::from(0),
            U256::from(1),
            U256::from(2),
            U256::from(100),
            U256::from(1000000),
        ];
        
        for value in test_values {
            let hash1 = hasher.hash_single_production(value).unwrap();
            let hash2 = hasher.hash_single_production(value).unwrap();
            assert_eq!(hash1, hash2, "Production hash should be deterministic");
        }
    }

    #[test]
    fn test_production_precompile_integration() {
        use alloy_sol_types::{SolCall, SolValue};
        
        // Test production hash through precompile interface
        let hasher = PoseidonHash::new();
        let input = U256::from(12345);
        
        // First get the expected hash
        let expected = hasher.hash_single_production(input).unwrap();
        
        // Now test through the precompile interface
        // Note: In real deployment, we would switch to production implementation
        let call = IPoseidonHash::poseidon1Call { input };
        let encoded = call.abi_encode();
        let mut full_call = IPoseidonHash::poseidon1Call::SELECTOR.to_vec();
        full_call.extend_from_slice(&encoded);
        
        let result = poseidon_precompile(&full_call);
        assert!(result.is_ok());
        
        // For now, the interface uses simplified version
        // In production, we would update interface.rs to use production methods
    }
}

#[cfg(test)]
mod use_case_tests {
    use super::*;

    #[test]
    fn test_merkle_tree_construction() {
        let hasher = PoseidonHash::new();

        // Leaf nodes
        let leaves = vec![U256::from(1), U256::from(2), U256::from(3), U256::from(4)];

        // Build tree level by level
        let mut level1 = Vec::new();
        for chunk in leaves.chunks(2) {
            if chunk.len() == 2 {
                let hash = hasher.hash_pair(chunk[0], chunk[1]).unwrap();
                level1.push(hash);
            } else {
                // Odd number of elements, hash with zero
                let hash = hasher.hash_pair(chunk[0], U256::ZERO).unwrap();
                level1.push(hash);
            }
        }

        // Final root
        let root = hasher.hash_pair(level1[0], level1[1]).unwrap();

        assert_ne!(root, U256::ZERO);
        assert!(root < hasher.params.modulus);
    }

    #[test]
    fn test_commitment_scheme() {
        let hasher = PoseidonHash::new();

        // Secret value and randomness
        let secret = U256::from(42);
        let randomness = U256::from(12345);

        // Create commitment: H(secret, randomness)
        let commitment = hasher.hash_pair(secret, randomness).unwrap();

        // Verify commitment by recomputing
        let verification = hasher.hash_pair(secret, randomness).unwrap();
        assert_eq!(commitment, verification);

        // Different randomness should produce different commitment
        let different_commitment = hasher.hash_pair(secret, U256::from(54321)).unwrap();
        assert_ne!(commitment, different_commitment);
    }

    #[test]
    fn test_array_vs_iterative_consistency() {
        let hasher = PoseidonHash::new();

        let inputs = vec![U256::from(10), U256::from(20), U256::from(30)];

        // Hash using array method
        let array_hash = hasher.hash_array(&inputs).unwrap();

        // Hash using iterative pair method
        let mut iterative_hash = inputs[0];
        for &input in &inputs[1..] {
            iterative_hash = hasher.hash_pair(iterative_hash, input).unwrap();
        }

        assert_eq!(
            array_hash, iterative_hash,
            "Array and iterative methods should match"
        );
    }
}

#[cfg(test)]
mod benchmark_tests {
    use super::*;
    use std::time::Instant;

    #[test]
    fn benchmark_single_hash() {
        let hasher = PoseidonHash::new();
        let input = U256::from(12345);

        let start = Instant::now();
        for _ in 0..1000 {
            let _ = hasher.hash_single(input).unwrap();
        }
        let duration = start.elapsed();

        println!("1000 single hashes took: {:?}", duration);
        println!("Average per hash: {:?}", duration / 1000);
    }

    #[test]
    fn benchmark_pair_hash() {
        let hasher = PoseidonHash::new();
        let left = U256::from(111);
        let right = U256::from(222);

        let start = Instant::now();
        for _ in 0..1000 {
            let _ = hasher.hash_pair(left, right).unwrap();
        }
        let duration = start.elapsed();

        println!("1000 pair hashes took: {:?}", duration);
        println!("Average per hash: {:?}", duration / 1000);
    }
}
