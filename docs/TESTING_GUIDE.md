# Testing Guide

Testing precompiles is different from testing regular contracts. Here's how to do it right.

## Why Testing Matters

When you mess up a smart contract, you can redeploy. When you mess up a precompile, it's more complicated. So we test everything.

## The Testing Stack

We test at three levels:
1. **Unit tests** - Does the algorithm work?
2. **Integration tests** - Does the ABI work?
3. **Contract tests** - Does it work from Solidity?

Each level catches different problems.

## Unit Testing

This is where you test the core logic.

### Basic Test

```rust
#[test]
fn test_hash_works() {
    let hasher = MyHasher::new();
    let result = hasher.compute(b"hello").unwrap();
    
    // Make sure it produces the right output
    assert_eq!(result.len(), 32);
    assert_ne!(result, vec![0u8; 32]); // Not all zeros
}
```

### Error Cases

Always test what happens when things go wrong:

```rust
#[test]
fn test_empty_input_fails() {
    let hasher = MyHasher::new();
    let result = hasher.compute(b"");
    
    assert!(result.is_err());
    match result {
        Err(MyError::EmptyInput) => (), // Expected
        _ => panic!("Wrong error type"),
    }
}

#[test]
fn test_oversized_input_fails() {
    let hasher = MyHasher::new();
    let huge_input = vec![0u8; 1_000_000]; // 1MB
    
    let result = hasher.compute(&huge_input);
    assert!(result.is_err());
}
```

### Known Test Vectors

If your algorithm has known outputs, use them:

```rust
#[test]
fn test_known_vectors() {
    let test_cases = vec![
        ("", "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"),
        ("hello", "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"),
    ];
    
    let hasher = Sha256::new();
    for (input, expected) in test_cases {
        let result = hasher.compute(input.as_bytes()).unwrap();
        assert_eq!(hex::encode(result), expected);
    }
}
```

## Integration Testing

This tests the full precompile interface.

### ABI Encoding Test

```rust
#[test]
fn test_abi_interface() {
    // Create the call data like Solidity would
    let input = U256::from(42);
    let call_data = IMyPrecompile::computeCall { input }.abi_encode();
    
    // Add function selector
    let mut full_input = IMyPrecompile::computeCall::SELECTOR.to_vec();
    full_input.extend_from_slice(&call_data);
    
    // Call the precompile
    let result = my_precompile(&full_input);
    assert!(result.is_ok());
    
    // Check output format
    let output = result.unwrap();
    assert_eq!(output.len(), 32); // U256 = 32 bytes
}
```

### Multiple Function Test

If your precompile has multiple functions:

```rust
#[test]
fn test_all_functions() {
    // Test function 1
    let result1 = call_precompile_function("hash", vec![1, 2, 3]);
    assert!(result1.is_ok());
    
    // Test function 2
    let result2 = call_precompile_function("verify", vec![4, 5, 6]);
    assert!(result2.is_ok());
    
    // Make sure they're different functions
    assert_ne!(result1, result2);
}
```

## Contract Testing

This is where you test from actual Solidity code.

### Setup

First, create a test contract:

```solidity
contract TestMyPrecompile {
    IMyPrecompile constant precompile = IMyPrecompile(0x0100);
    
    function testBasicOperation() external pure returns (bytes memory) {
        return precompile.compute("test");
    }
    
    function testErrorHandling() external view {
        try precompile.compute("") {
            revert("Should have failed");
        } catch {
            // Expected
        }
    }
}
```

### JavaScript Tests

Write tests using Hardhat:

```javascript
describe("MyPrecompile", function () {
    let tester;
    
    beforeEach(async function () {
        const TestContract = await ethers.getContractFactory("TestMyPrecompile");
        tester = await TestContract.deploy();
    });
    
    it("should compute correctly", async function () {
        const result = await tester.testBasicOperation();
        expect(result).to.not.equal("0x");
        expect(result.length).to.equal(66); // 0x + 64 hex chars
    });
    
    it("should handle errors", async function () {
        // This should not revert since the contract handles the error
        await expect(tester.testErrorHandling()).to.not.be.reverted;
    });
});
```

## Gas Testing

This is crucial for precompiles. The whole point is to save gas.

### Benchmark Contract

```solidity
contract GasBenchmark {
    function measurePrecompileGas(bytes calldata input) external returns (uint256) {
        uint256 gasBefore = gasleft();
        precompile.compute(input);
        uint256 gasAfter = gasleft();
        
        return gasBefore - gasAfter;
    }
    
    function measureSolidityGas(bytes calldata input) external returns (uint256) {
        uint256 gasBefore = gasleft();
        computeInSolidity(input);
        uint256 gasAfter = gasleft();
        
        return gasBefore - gasAfter;
    }
}
```

### Running Benchmarks

```javascript
it("should use less gas than Solidity", async function () {
    const input = ethers.utils.toUtf8Bytes("benchmark input");
    
    const precompileGas = await benchmark.measurePrecompileGas(input);
    const solidityGas = await benchmark.measureSolidityGas(input);
    
    console.log(`Precompile: ${precompileGas} gas`);
    console.log(`Solidity: ${solidityGas} gas`);
    console.log(`Savings: ${Math.round((1 - precompileGas/solidityGas) * 100)}%`);
    
    expect(precompileGas).to.be.lessThan(solidityGas);
});
```

## Debugging Failed Tests

### When Unit Tests Fail

Add debug output:
```rust
#[test]
fn test_with_debugging() {
    let input = b"test";
    println!("Input: {:?}", input);
    
    let result = compute(input);
    println!("Result: {:?}", result);
    
    assert!(result.is_ok());
}
```

Run with output:
```bash
cargo test -- --nocapture
```

### When Integration Tests Fail

Check the selector:
```rust
println!("Expected selector: {:?}", IMyPrecompile::computeCall::SELECTOR);
println!("Received selector: {:?}", &input[0..4]);
```

### When Contract Tests Fail

Use Hardhat console:
```solidity
import "hardhat/console.sol";

function debug() external {
    console.log("Calling precompile...");
    bytes memory result = precompile.compute("test");
    console.logBytes(result);
}
```

## Test Coverage

Make sure you test:
- ✅ Normal inputs
- ✅ Edge cases (empty, max size)
- ✅ Invalid inputs
- ✅ All functions
- ✅ Gas usage
- ✅ Concurrent calls

## Running All Tests

```bash
# Rust tests
cargo test

# Contract tests
cd contracts
npm test

# Everything
./scripts/test_all.sh
```

## CI/CD Integration

Add to your GitHub Actions:
```yaml
- name: Run tests
  run: |
    cargo test --all
    cd contracts && npm test
```

## The Most Important Test

Does it actually save gas? If not, why are we doing this?

Always benchmark against the Solidity equivalent. That's the number that matters.

---

That's testing. Do it right, and your precompile will work. Skip it, and you'll find out in production.