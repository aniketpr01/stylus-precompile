//! Benchmark tests for Poseidon hash precompile

use alloy_primitives::U256;
use precompile::*;
use std::time::Instant;

#[cfg(test)]
mod benchmark_tests {
    use super::*;

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

        // Ensure it's reasonably fast (adjust threshold as needed)
        assert!(
            duration.as_millis() < 5000,
            "Single hash benchmark too slow"
        );
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

        assert!(duration.as_millis() < 10000, "Pair hash benchmark too slow");
    }

    #[test]
    fn benchmark_array_hash() {
        let hasher = PoseidonHash::new();
        let inputs = vec![
            U256::from(1),
            U256::from(2),
            U256::from(3),
            U256::from(4),
            U256::from(5),
        ];

        let start = Instant::now();
        for _ in 0..1000 {
            let _ = hasher.hash_array(&inputs).unwrap();
        }
        let duration = start.elapsed();

        println!("1000 array hashes (5 elements) took: {:?}", duration);
        println!("Average per hash: {:?}", duration / 1000);

        assert!(
            duration.as_millis() < 15000,
            "Array hash benchmark too slow"
        );
    }

    #[test]
    fn benchmark_precompile_interface() {
        let input = U256::from(42);
        let call_data = IPoseidonHash::poseidon1Call { input }.abi_encode();
        let mut full_input = IPoseidonHash::poseidon1Call::SELECTOR.to_vec();
        full_input.extend_from_slice(&call_data);

        let start = Instant::now();
        for _ in 0..1000 {
            let _ = poseidon_precompile(&full_input).unwrap();
        }
        let duration = start.elapsed();

        println!("1000 precompile calls took: {:?}", duration);
        println!("Average per call: {:?}", duration / 1000);

        assert!(
            duration.as_millis() < 10000,
            "Precompile interface benchmark too slow"
        );
    }
}
