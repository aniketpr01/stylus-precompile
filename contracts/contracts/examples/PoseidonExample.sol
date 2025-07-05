// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IPoseidonHash.sol";

/**
 * @title PoseidonExample
 * @dev Example contract demonstrating Poseidon hash precompile usage
 * @notice This contract shows various use cases for the Poseidon hash function
 */
contract PoseidonExample {
    /// @dev Address of the Poseidon precompile
    address public constant POSEIDON_PRECOMPILE = address(0x100);
    
    /// @dev Event emitted when a hash is computed
    event HashComputed(string method, bytes32 hash, uint256 gasUsed);
    
    /**
     * @dev Compute Poseidon hash of a single value
     * @param value The value to hash
     * @return hash The computed hash
     */
    function hashSingle(uint256 value) external returns (uint256 hash) {
        uint256 gasStart = gasleft();
        
        (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash.selector, value)
        );
        
        require(success, "Poseidon1 call failed");
        hash = abi.decode(result, (uint256));
        
        emit HashComputed("hash", bytes32(hash), gasStart - gasleft());
    }
    
    /**
     * @dev Compute Poseidon hash of two values (simulated using single hash)
     * Note: The deployed precompile only supports single hash, so we simulate pair hashing
     * @param left The left value
     * @param right The right value
     * @return hash The computed hash
     */
    function hashPair(uint256 left, uint256 right) external returns (uint256 hash) {
        uint256 gasStart = gasleft();
        
        // Simulate pair hashing by combining values and using single hash
        uint256 combined = addmod(left, right, 21888242871839275222246405745257275088548364400416034343698204186575808495617);
        
        (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash.selector, combined)
        );
        
        require(success, "Poseidon hash call failed");
        hash = abi.decode(result, (uint256));
        
        emit HashComputed("hash_pair_simulated", bytes32(hash), gasStart - gasleft());
    }
    
    /**
     * @dev Compute Poseidon hash of an array (simulated using single hash)
     * Note: The deployed precompile only supports single hash, so we simulate array hashing
     * @param values The array of values to hash
     * @return hash The computed hash
     */
    function hashArray(uint256[] calldata values) external returns (uint256 hash) {
        require(values.length > 0, "Array cannot be empty");
        uint256 gasStart = gasleft();
        
        hash = values[0];
        for (uint256 i = 1; i < values.length; i++) {
            // Simulate pair hashing by combining values and using single hash
            uint256 combined = addmod(hash, values[i], 21888242871839275222246405745257275088548364400416034343698204186575808495617);
            (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
                abi.encodeWithSelector(IPoseidonHash.hash.selector, combined)
            );
            require(success, "Poseidon hash call failed");
            hash = abi.decode(result, (uint256));
        }
        
        emit HashComputed("poseidonArray_simulated", bytes32(hash), gasStart - gasleft());
    }
    
    /**
     * @dev Example: Hash-based commitment scheme (simulated using single hash)
     * Note: The deployed precompile only supports single hash, so we simulate pair hashing
     * @param secret The secret value
     * @param nonce A random nonce
     * @return commitment The commitment hash
     */
    function createCommitment(uint256 secret, uint256 nonce) external view returns (uint256 commitment) {
        // Simulate pair hashing by combining values and using single hash
        uint256 combined = addmod(secret, nonce, 21888242871839275222246405745257275088548364400416034343698204186575808495617);
        
        (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash.selector, combined)
        );
        
        require(success, "Commitment creation failed");
        commitment = abi.decode(result, (uint256));
    }
    
    /**
     * @dev Example: Merkle tree leaf computation (simulated using single hash)
     * Note: The deployed precompile only supports single hash, so we simulate pair hashing
     * @param data The leaf data
     * @param index The leaf index
     * @return leaf The computed leaf hash
     */
    function computeLeaf(uint256 data, uint256 index) external view returns (uint256 leaf) {
        // Simulate pair hashing by combining values and using single hash
        uint256 combined = addmod(data, index, 21888242871839275222246405745257275088548364400416034343698204186575808495617);
        
        (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash.selector, combined)
        );
        
        require(success, "Leaf computation failed");
        leaf = abi.decode(result, (uint256));
    }
    
    /**
     * @dev Example: Hash chain computation
     * @param seed Initial seed value
     * @param length Length of the hash chain
     * @return finalHash The final hash in the chain
     */
    function computeHashChain(uint256 seed, uint256 length) external view returns (uint256 finalHash) {
        finalHash = seed;
        
        for (uint256 i = 0; i < length; i++) {
            (bool success, bytes memory result) = POSEIDON_PRECOMPILE.staticcall(
                abi.encodeWithSelector(IPoseidonHash.hash.selector, finalHash)
            );
            
            require(success, "Hash chain computation failed");
            finalHash = abi.decode(result, (uint256));
        }
    }
}