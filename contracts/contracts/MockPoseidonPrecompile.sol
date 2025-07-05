// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPoseidonHash.sol";

/**
 * @title MockPoseidonPrecompile
 * @dev Mock implementation of Poseidon precompile for testing
 * @notice This is a simplified implementation for testing purposes only
 */
contract MockPoseidonPrecompile is IPoseidonHash {
    /// @dev BN254 scalar field modulus
    uint256 public constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /**
     * @dev Mock implementation of single element Poseidon hash
     */
    function hash(uint256 input) external pure override returns (uint256) {
        require(input < FIELD_MODULUS, "Input exceeds field modulus");
        
        // Simplified mock implementation - not cryptographically secure
        uint256 result = input;
        for (uint i = 0; i < 8; i++) {
            result = addmod(
                mulmod(result, result, FIELD_MODULUS),
                123456789,
                FIELD_MODULUS
            );
        }
        
        return result;
    }

    /**
     * @dev Mock implementation of two element Poseidon hash
     */
    function hash_pair(uint256 a, uint256 b) external pure override returns (uint256) {
        require(a < FIELD_MODULUS, "First input exceeds field modulus");
        require(b < FIELD_MODULUS, "Second input exceeds field modulus");
        
        // Simplified mock implementation
        uint256 combined = addmod(a, b, FIELD_MODULUS);
        return _poseidon1Internal(combined);
    }


    /**
     * @dev Internal pure implementation of single element Poseidon hash
     */
    function _poseidon1Internal(uint256 input) internal pure returns (uint256) {
        // Simplified mock implementation - not cryptographically secure
        uint256 result = input;
        for (uint i = 0; i < 8; i++) {
            result = addmod(
                mulmod(result, result, FIELD_MODULUS),
                123456789,
                FIELD_MODULUS
            );
        }
        
        return result;
    }

    /**
     * @dev Internal pure implementation of two element Poseidon hash
     */
    function _poseidon2Internal(uint256 left, uint256 right) internal pure returns (uint256) {
        // Simplified mock implementation
        uint256 combined = addmod(left, right, FIELD_MODULUS);
        return _poseidon1Internal(combined);
    }
}