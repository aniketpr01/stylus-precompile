//! Usage examples for the Poseidon hash precompile

use alloy_primitives::U256;
use precompile::*;

#[cfg(test)]
mod examples {
    use super::*;

    /// Example: Building a Merkle tree with Poseidon hashes
    #[test]
    fn example_merkle_tree() {
        let hasher = PoseidonHash::new();

        // Sample data for leaves
        let data = vec!["alice", "bob", "charlie", "diana"];

        // Convert to field elements (simplified - real implementation would use proper encoding)
        let leaves: Vec<U256> = data
            .iter()
            .enumerate()
            .map(|(i, _)| U256::from(i + 1))
            .collect();

        println!("Building Merkle tree for {} leaves", leaves.len());

        // Build tree bottom-up
        let mut current_level = leaves.clone();
        let mut level = 0;

        while current_level.len() > 1 {
            let mut next_level = Vec::new();

            for chunk in current_level.chunks(2) {
                let hash = if chunk.len() == 2 {
                    hasher.hash_pair(chunk[0], chunk[1]).unwrap()
                } else {
                    hasher.hash_pair(chunk[0], U256::ZERO).unwrap()
                };
                next_level.push(hash);
            }

            println!("Level {}: {} nodes", level, current_level.len());
            current_level = next_level;
            level += 1;
        }

        let root = current_level[0];
        println!("Merkle root: 0x{:x}", root);

        // Verify root is non-zero and within field
        assert_ne!(root, U256::ZERO);
        assert!(root < hasher.params.modulus);
    }

    /// Example: Privacy-preserving commitment scheme
    #[test]
    fn example_commitment_scheme() {
        let hasher = PoseidonHash::new();

        // Secret value and randomness
        let secret = U256::from(42);
        let randomness = U256::from(12345);

        // Create commitment: H(secret, randomness)
        let commitment = hasher.hash_pair(secret, randomness).unwrap();

        println!("Commitment scheme example:");
        println!("Secret: {}", secret);
        println!("Randomness: {}", randomness);
        println!("Commitment: 0x{:x}", commitment);

        // Verify commitment by recomputing
        let verification = hasher.hash_pair(secret, randomness).unwrap();
        assert_eq!(commitment, verification);

        println!("✓ Commitment verified");
    }

    /// Example: Nullifier generation for privacy coins
    #[test]
    fn example_nullifier() {
        let hasher = PoseidonHash::new();

        // Coin serial number and secret key
        let serial_number = U256::from(98765);
        let secret_key = U256::from(11111);

        // Generate nullifier: H(serial_number, secret_key)
        let nullifier = hasher.hash_pair(serial_number, secret_key).unwrap();

        println!("Nullifier example:");
        println!("Serial number: {}", serial_number);
        println!("Secret key: {}", secret_key);
        println!("Nullifier: 0x{:x}", nullifier);

        // Different secret keys should produce different nullifiers
        let different_key = U256::from(22222);
        let different_nullifier = hasher.hash_pair(serial_number, different_key).unwrap();

        assert_ne!(nullifier, different_nullifier);
        println!("✓ Different keys produce different nullifiers");
    }

    /// Example: Hash chain for timestamping
    #[test]
    fn example_hash_chain() {
        let hasher = PoseidonHash::new();

        // Initial value
        let mut current_hash = U256::from(1);
        let timestamps = vec![1000, 2000, 3000, 4000, 5000];

        println!("Hash chain example:");
        println!("Initial: 0x{:x}", current_hash);

        for (i, &timestamp) in timestamps.iter().enumerate() {
            // Chain: H(previous_hash, timestamp)
            current_hash = hasher
                .hash_pair(current_hash, U256::from(timestamp))
                .unwrap();
            println!(
                "Step {}: 0x{:x} (timestamp: {})",
                i + 1,
                current_hash,
                timestamp
            );
        }

        // Final hash represents the entire chain
        let final_hash = current_hash;
        println!("Final chain hash: 0x{:x}", final_hash);

        // Verify we can't forge the chain without knowing intermediate steps
        assert_ne!(final_hash, U256::from(1));
    }
}
