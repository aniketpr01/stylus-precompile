// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPoseidonHash
 * @dev Interface for Poseidon hash precompile
 * @notice Poseidon is a cryptographic hash function optimized for zero-knowledge proof systems
 */
interface IPoseidonHash {
    /**
     * @dev Computes Poseidon hash of a single field element
     * @param input The field element to hash (must be < BN254 scalar field modulus)
     * @return hash The resulting Poseidon hash
     */
    function hash(uint256 input) external pure returns (uint256 hash);

    /**
     * @dev Computes Poseidon hash of two field elements
     * @param a The first field element
     * @param b The second field element
     * @return hash The resulting Poseidon hash
     */
    function hash_pair(uint256 a, uint256 b) external pure returns (uint256 hash);

}

/**
 * @title PoseidonHashPrecompile
 * @dev Wrapper contract for the Poseidon hash precompile
 * @notice This contract provides a convenient interface to the WASM precompile
 */
contract PoseidonHashPrecompile {
    /// @dev Address where the Poseidon precompile is deployed
    address public constant POSEIDON_PRECOMPILE = address(0x100);

    /// @dev BN254 scalar field modulus
    uint256 public constant FIELD_MODULUS =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    /**
     * @dev Validates that a value is a valid field element
     * @param value The value to validate
     */
    modifier validFieldElement(uint256 value) {
        require(value < FIELD_MODULUS, "Value exceeds field modulus");
        _;
    }

    /**
     * @dev Validates that all values in an array are valid field elements
     * @param values The array to validate
     */
    modifier validFieldElements(uint256[] calldata values) {
        require(values.length > 0, "Array cannot be empty");
        for (uint256 i = 0; i < values.length; i++) {
            require(values[i] < FIELD_MODULUS, "Value exceeds field modulus");
        }
        _;
    }

    /**
     * @dev Computes Poseidon hash of a single field element
     */
    function hash(uint256 input)
        external
        view
        validFieldElement(input)
        returns (uint256 result)
    {
        (bool success, bytes memory output) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash.selector, input)
        );

        require(success, "Precompile call failed");
        result = abi.decode(output, (uint256));
    }

    /**
     * @dev Computes Poseidon hash of two field elements
     */
    function hash_pair(uint256 a, uint256 b)
        external
        view
        validFieldElement(a)
        validFieldElement(b)
        returns (uint256 result)
    {
        (bool success, bytes memory output) = POSEIDON_PRECOMPILE.staticcall(
            abi.encodeWithSelector(IPoseidonHash.hash_pair.selector, a, b)
        );

        require(success, "Precompile call failed");
        result = abi.decode(output, (uint256));
    }

}
