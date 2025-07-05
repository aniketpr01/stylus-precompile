//! Utility functions for the precompile library

use alloy_primitives::U256;

/// Converts a hex string to U256
pub fn hex_to_u256(hex_str: &str) -> Result<U256, &'static str> {
    let clean_hex = hex_str.strip_prefix("0x").unwrap_or(hex_str);
    U256::from_str_radix(clean_hex, 16).map_err(|_| "Invalid hex string")
}

/// Converts U256 to hex string with 0x prefix
pub fn u256_to_hex(value: U256) -> String {
    format!("0x{:x}", value)
}

/// Utility functions for precompile development

/// Convert bytes to hex string for debugging
pub fn bytes_to_hex(bytes: &[u8]) -> String {
    hex::encode(bytes)
}

/// Validate BN254 field element
pub fn is_valid_bn254_field_element(value: U256) -> bool {
    // BN254 scalar field modulus
    let bn254_modulus = U256::from_str_radix(
        "21888242871839275222246405745257275088548364400416034343698204186575808495617",
        10,
    )
    .unwrap();

    value < bn254_modulus
}

/// Generate test field elements for testing
#[cfg(test)]
pub fn generate_test_elements(count: usize) -> Vec<U256> {
    (1..=count).map(|i| U256::from(i * 42)).collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hex_conversion() {
        let value = U256::from(42);
        let hex_str = u256_to_hex(value);
        let converted_back = hex_to_u256(&hex_str).unwrap();
        assert_eq!(value, converted_back);
    }
}
