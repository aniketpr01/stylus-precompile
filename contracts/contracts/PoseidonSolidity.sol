// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PoseidonSolidity
 * @dev A more realistic Solidity implementation of Poseidon hash for gas benchmarking
 * @notice This is a simplified version that maintains the computational complexity of Poseidon
 */
library PoseidonSolidity {
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant ALPHA = 5; // x^5 S-box
    uint256 constant NUM_FULL_ROUNDS = 8;
    uint256 constant NUM_PARTIAL_ROUNDS = 57;
    uint256 constant WIDTH = 3; // t = 3 for efficiency
    
    // Simplified round constants (in production these would be specific values)
    function getRoundConstant(uint256 round) internal pure returns (uint256) {
        // Using a deterministic pseudo-random function for round constants
        return uint256(keccak256(abi.encodePacked("poseidon_round_", round))) % FIELD_MODULUS;
    }
    
    // Simplified MDS matrix multiplication
    function mdsMatrixMul(uint256[WIDTH] memory state) internal pure returns (uint256[WIDTH] memory) {
        uint256[WIDTH] memory result;
        
        // Simplified MDS matrix (in production this would be a specific matrix)
        // Using a circulant matrix pattern for simplicity
        for (uint256 i = 0; i < WIDTH; i++) {
            result[i] = 0;
            for (uint256 j = 0; j < WIDTH; j++) {
                uint256 mdsElement = ((i + j) % WIDTH) + 1;
                result[i] = addmod(result[i], mulmod(state[j], mdsElement, FIELD_MODULUS), FIELD_MODULUS);
            }
        }
        
        return result;
    }
    
    // S-box: x^5 mod p
    function sbox(uint256 x) internal pure returns (uint256) {
        uint256 x2 = mulmod(x, x, FIELD_MODULUS);
        uint256 x4 = mulmod(x2, x2, FIELD_MODULUS);
        return mulmod(x4, x, FIELD_MODULUS);
    }
    
    // Full round function
    function fullRound(uint256[WIDTH] memory state, uint256 roundNum) internal pure returns (uint256[WIDTH] memory) {
        // Add round constants
        for (uint256 i = 0; i < WIDTH; i++) {
            state[i] = addmod(state[i], getRoundConstant(roundNum * WIDTH + i), FIELD_MODULUS);
        }
        
        // Apply S-box to all elements
        for (uint256 i = 0; i < WIDTH; i++) {
            state[i] = sbox(state[i]);
        }
        
        // Apply MDS matrix
        state = mdsMatrixMul(state);
        
        return state;
    }
    
    // Partial round function (S-box only on first element)
    function partialRound(uint256[WIDTH] memory state, uint256 roundNum) internal pure returns (uint256[WIDTH] memory) {
        // Add round constants
        for (uint256 i = 0; i < WIDTH; i++) {
            state[i] = addmod(state[i], getRoundConstant(roundNum * WIDTH + i), FIELD_MODULUS);
        }
        
        // Apply S-box only to first element
        state[0] = sbox(state[0]);
        
        // Apply MDS matrix
        state = mdsMatrixMul(state);
        
        return state;
    }
    
    /**
     * @dev Hash a single field element
     */
    function hash(uint256 input) internal pure returns (uint256) {
        require(input < FIELD_MODULUS, "Input exceeds field modulus");
        
        // Initialize state [input, 0, 0]
        uint256[WIDTH] memory state;
        state[0] = input;
        state[1] = 0;
        state[2] = 0;
        
        // First half of full rounds
        for (uint256 i = 0; i < NUM_FULL_ROUNDS / 2; i++) {
            state = fullRound(state, i);
        }
        
        // Partial rounds
        for (uint256 i = 0; i < NUM_PARTIAL_ROUNDS; i++) {
            state = partialRound(state, NUM_FULL_ROUNDS / 2 + i);
        }
        
        // Second half of full rounds
        for (uint256 i = 0; i < NUM_FULL_ROUNDS / 2; i++) {
            state = fullRound(state, NUM_FULL_ROUNDS / 2 + NUM_PARTIAL_ROUNDS + i);
        }
        
        return state[0];
    }
    
    /**
     * @dev Hash two field elements
     */
    function hashPair(uint256 left, uint256 right) internal pure returns (uint256) {
        require(left < FIELD_MODULUS && right < FIELD_MODULUS, "Input exceeds field modulus");
        
        // Initialize state [left, right, 0]
        uint256[WIDTH] memory state;
        state[0] = left;
        state[1] = right;
        state[2] = 0;
        
        // First half of full rounds
        for (uint256 i = 0; i < NUM_FULL_ROUNDS / 2; i++) {
            state = fullRound(state, i);
        }
        
        // Partial rounds
        for (uint256 i = 0; i < NUM_PARTIAL_ROUNDS; i++) {
            state = partialRound(state, NUM_FULL_ROUNDS / 2 + i);
        }
        
        // Second half of full rounds
        for (uint256 i = 0; i < NUM_FULL_ROUNDS / 2; i++) {
            state = fullRound(state, NUM_FULL_ROUNDS / 2 + NUM_PARTIAL_ROUNDS + i);
        }
        
        return state[0];
    }
    
    /**
     * @dev Hash an array of field elements
     */
    function hashArray(uint256[] memory inputs) internal pure returns (uint256) {
        require(inputs.length > 0, "Empty array");
        
        if (inputs.length == 1) {
            return hash(inputs[0]);
        }
        
        // Hash pairs recursively
        uint256 result = hashPair(inputs[0], inputs[1]);
        for (uint256 i = 2; i < inputs.length; i++) {
            result = hashPair(result, inputs[i]);
        }
        
        return result;
    }
}