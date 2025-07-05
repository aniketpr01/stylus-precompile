//! CLI runner for manual testing of the Poseidon precompile

use alloy_primitives::U256;
use alloy_sol_types::{SolCall, SolValue};
use precompile::*;

#[cfg(test)]
mod cli_tests {
    use super::*;

    #[test]
    fn run_interactive_test() {
        println!("\n=== Poseidon Hash Precompile Interactive Test ===");

        let hasher = PoseidonHash::new();

        // Test 1: Single element hash
        println!("\n1. Single Element Hash:");
        let input = U256::from(42);
        let hash = hasher.hash_single(input).unwrap();
        println!("   Input: {}", input);
        println!("   Hash:  0x{:x}", hash);

        // Test 2: Pair hash
        println!("\n2. Pair Hash:");
        let left = U256::from(100);
        let right = U256::from(200);
        let pair_hash = hasher.hash_pair(left, right).unwrap();
        println!("   Left:  {}", left);
        println!("   Right: {}", right);
        println!("   Hash:  0x{:x}", pair_hash);

        // Test 3: Array hash
        println!("\n3. Array Hash:");
        let array = vec![U256::from(1), U256::from(2), U256::from(3)];
        let array_hash = hasher.hash_array(&array).unwrap();
        println!("   Array: {:?}", array);
        println!("   Hash:  0x{:x}", array_hash);

        // Test 4: Precompile interface
        println!("\n4. Precompile Interface Test:");
        let call = IPoseidonHash::poseidon1Call {
            input: U256::from(999),
        };
        let encoded = call.abi_encode();
        let mut full_call = IPoseidonHash::poseidon1Call::SELECTOR.to_vec();
        full_call.extend_from_slice(&encoded);

        let result = poseidon_precompile(&full_call).unwrap();
        let decoded_hash = U256::abi_decode(&result, true).unwrap();
        println!("   Precompile Input: 999");
        println!("   Precompile Hash:  0x{:x}", decoded_hash);

        // Test 5: Field validation
        println!("\n5. Field Validation Test:");
        let valid_element = hasher.params.modulus - U256::from(1);
        let invalid_element = hasher.params.modulus;

        println!(
            "   Valid element:   {} -> {}",
            valid_element,
            hasher.validate_field_element(valid_element).is_ok()
        );
        println!(
            "   Invalid element: {} -> {}",
            invalid_element,
            hasher.validate_field_element(invalid_element).is_ok()
        );

        println!("\n=== Test Complete ===\n");
    }
}
