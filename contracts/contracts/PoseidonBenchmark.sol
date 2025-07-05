// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPoseidonHash.sol";
import "./PoseidonSolidity.sol";

/**
 * @title PoseidonBenchmark
 * @dev Comprehensive gas benchmarking for Poseidon precompile vs pure Solidity
 */
contract PoseidonBenchmark {
    IPoseidonHash public immutable poseidonPrecompile;

    // Events for tracking gas usage
    event PrecompileGasUsed(uint256 gasUsed);
    event SolidityGasUsed(uint256 gasUsed);
    event GasComparison(string operation, uint256 precompileGas, uint256 solidityGas, uint256 improvement);

    constructor(address _precompileAddress) {
        poseidonPrecompile = IPoseidonHash(_precompileAddress);
    }

    /**
     * @dev Benchmark single element hashing
     */
    function benchmarkSingleHash(uint256 input) external {
        // Test precompile
        uint256 gasStart = gasleft();
        uint256 precompileResult = poseidonPrecompile.hash(input);
        uint256 precompileGas = gasStart - gasleft();

        // Test pure Solidity (simplified implementation)
        gasStart = gasleft();
        uint256 solidityResult = solidityPoseidonSingle(input);
        uint256 solidityGas = gasStart - gasleft();

        emit PrecompileGasUsed(precompileGas);
        emit SolidityGasUsed(solidityGas);

        uint256 improvement = solidityGas > precompileGas ? ((solidityGas - precompileGas) * 100) / solidityGas : 0;
        emit GasComparison("single_hash", precompileGas, solidityGas, improvement);
    }

    /**
     * @dev Benchmark pair hashing (simulated using single hash)
     * Note: The deployed precompile only supports single hash, so we simulate pair hashing
     */
    function benchmarkPairHash(uint256 left, uint256 right) external {
        // Test precompile (simulated pair hash using single hash)
        uint256 gasStart = gasleft();
        // Combine inputs using addition and hash the result
        uint256 combined = addmod(left, right, 21888242871839275222246405745257275088548364400416034343698204186575808495617);
        uint256 precompileResult = poseidonPrecompile.hash(combined);
        uint256 precompileGas = gasStart - gasleft();

        // Test pure Solidity
        gasStart = gasleft();
        uint256 solidityResult = solidityPoseidonPair(left, right);
        uint256 solidityGas = gasStart - gasleft();

        emit PrecompileGasUsed(precompileGas);
        emit SolidityGasUsed(solidityGas);

        uint256 improvement = solidityGas > precompileGas ? ((solidityGas - precompileGas) * 100) / solidityGas : 0;
        emit GasComparison("pair_hash_simulated", precompileGas, solidityGas, improvement);
    }

    /**
     * @dev Benchmark simulated array hashing using single hash
     * Note: The deployed precompile only supports single hash, so we simulate array hashing
     */
    function benchmarkArrayHash(uint256[] calldata inputs) external {
        require(inputs.length > 0 && inputs.length <= 10, "Array size must be 1-10");

        // Test simulated precompile array hash using single hash
        uint256 gasStart = gasleft();
        uint256 precompileResult = inputs[0];
        for (uint i = 1; i < inputs.length; i++) {
            // Simulate pair hashing by combining values and using single hash
            uint256 combined = addmod(precompileResult, inputs[i], 21888242871839275222246405745257275088548364400416034343698204186575808495617);
            precompileResult = poseidonPrecompile.hash(combined);
        }
        uint256 precompileGas = gasStart - gasleft();

        // Test pure Solidity
        gasStart = gasleft();
        uint256 solidityResult = solidityPoseidonArray(inputs);
        uint256 solidityGas = gasStart - gasleft();

        emit PrecompileGasUsed(precompileGas);
        emit SolidityGasUsed(solidityGas);

        uint256 improvement = solidityGas > precompileGas ? ((solidityGas - precompileGas) * 100) / solidityGas : 0;
        emit GasComparison("array_hash_simulated", precompileGas, solidityGas, improvement);
    }

    /**
     * @dev Use the realistic Solidity Poseidon implementation for fair comparison
     */
    function solidityPoseidonSingle(uint256 input) internal pure returns (uint256) {
        return PoseidonSolidity.hash(input);
    }

    function solidityPoseidonPair(uint256 left, uint256 right) internal pure returns (uint256) {
        return PoseidonSolidity.hashPair(left, right);
    }

    function solidityPoseidonArray(uint256[] calldata inputs) internal pure returns (uint256) {
        return PoseidonSolidity.hashArray(inputs);
    }

    /**
     * @dev Batch testing for comprehensive benchmarks - Optimized for essential operations
     */
    function runComprehensiveBenchmark() external {
        // Essential single element test
        this.benchmarkSingleHash(12345);

        // Essential pair test
        this.benchmarkPairHash(111, 222);

        // Essential array test (small size only)
        uint256[] memory small = new uint256[](3);
        small[0] = 100;
        small[1] = 200;
        small[2] = 300;
        this.benchmarkArrayHash(small);
    }
}
