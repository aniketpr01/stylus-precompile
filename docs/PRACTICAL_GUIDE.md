# Practical Guide

Let's build something. This guide shows you how to actually use this framework.

## Quick Start

Here's the fastest way to get going:

```bash
# Get the code
git clone <repository-url>
cd precompile
cargo build --release

# Create a new precompile (takes 30 seconds)
./scripts/generate_precompile.sh sha256

# Build it
cargo build --target wasm32-unknown-unknown --release

# Test it
cargo test sha256

# Deploy it
./scripts/deploy.sh --network arbitrum-sepolia --private-key $PRIVATE_KEY
```

That's it. You now have a working precompile.

## Setting Things Up

### What You Need

First, make sure you have Rust:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup update
rustup target add wasm32-unknown-unknown
```

You'll also need Node.js for testing contracts:
```bash
# If you use nvm
nvm install 18
nvm use 18
```

### Getting the Framework

```bash
git clone <repository-url>
cd precompile

# Build everything
cargo build --release

# Install contract dependencies
cd contracts
npm install
cd ..

# Make sure it works
cargo test
```

If the tests pass, you're ready.

## Creating Your First Precompile

Let's build a SHA256 precompile as an example.

### Step 1: Generate the Template

```bash
./scripts/generate_precompile.sh sha256
```

This creates:
- `src/sha256/` - Your Rust code goes here
- `contracts/interfaces/ISha256.sol` - Solidity interface
- `tests/sha256_tests.rs` - Test file

### Step 2: Add Your Dependencies

Edit `Cargo.toml`:
```toml
[dependencies]
sha2 = "0.10"
```

### Step 3: Write the Implementation

Edit `src/sha256/core.rs`:
```rust
use sha2::{Sha256, Digest};
use crate::errors::Sha256Error;

impl Sha256Hash {
    pub fn compute(&self, input: &[u8]) -> Result<Vec<u8>, Sha256Error> {
        // Check input
        self.validate_input(input)?;
        
        // Do the hash
        let mut hasher = Sha256::new();
        hasher.update(input);
        let result = hasher.finalize();
        
        Ok(result.to_vec())
    }
}
```

That's the core logic. Simple.

### Step 4: Test It

Write a test in `tests/sha256_tests.rs`:
```rust
#[test]
fn test_sha256_works() {
    let sha256 = Sha256Hash::new();
    let result = sha256.compute(b"hello world").unwrap();
    
    // This is the actual SHA256 of "hello world"
    let expected = hex::decode("b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9").unwrap();
    assert_eq!(result, expected);
}
```

Run it:
```bash
cargo test sha256
```

## How Poseidon Works (The Real Example)

We already built Poseidon, so let's look at how it actually works.

### The Implementation

In `src/poseidon/core.rs`:
```rust
pub fn hash_single(&self, input: U256) -> Result<U256, PoseidonError> {
    // Make sure input is valid
    self.validate_field_element(input)?;
    
    // Convert to field element
    let mut bytes = [0u8; 32];
    input.to_big_endian(&mut bytes);
    let fr = Fr::from_repr(FrRepr(bytes)).unwrap();
    
    // Hash it
    let mut hasher = PoseidonRs::new();
    hasher.update(fr);
    let result = hasher.finalize();
    
    // Convert back
    let mut result_bytes = [0u8; 32];
    result.into_repr().write_be(&mut result_bytes[..]).unwrap();
    Ok(U256::from_big_endian(&result_bytes))
}
```

### Using It in Contracts

```solidity
contract MyZKApp {
    IPoseidon constant poseidon = IPoseidon(0x0100);
    
    function commitToValue(uint256 secret, uint256 nonce) external {
        uint256 commitment = poseidon.poseidon2(secret, nonce);
        // Do something with the commitment
    }
}
```

### The Performance

Real numbers from Arbitrum Sepolia:
- Poseidon in Solidity: 553,176 gas
- Our precompile: 41,056 gas
- You save: 93%

## Testing Your Precompile

Testing is critical. Here's how we do it.

### Unit Tests

Test the core logic:
```rust
#[test]
fn test_basic_functionality() {
    let precompile = MyPrecompile::new();
    let result = precompile.compute(b"test").unwrap();
    assert_eq!(result.len(), 32);
}

#[test]
fn test_error_handling() {
    let precompile = MyPrecompile::new();
    let result = precompile.compute(b""); // Empty input
    assert!(result.is_err());
}
```

### Integration Tests

Test the ABI interface:
```rust
#[test]
fn test_abi_encoding() {
    let input = U256::from(42);
    let encoded = encode_function_data(input);
    let result = my_precompile(&encoded).unwrap();
    assert_eq!(result.len(), 32);
}
```

### Contract Tests

Test from Solidity:
```javascript
it("should compute hash correctly", async function () {
    const input = "Hello World";
    const result = await precompile.compute(ethers.utils.toUtf8Bytes(input));
    expect(result).to.have.lengthOf(64); // 32 bytes as hex
});
```

## Deploying to Arbitrum

### The Easy Way

```bash
./scripts/deploy.sh --network arbitrum-sepolia --private-key $PRIVATE_KEY
```

### What Actually Happens

1. Builds your WASM binary
2. Optimizes it (important for gas costs)
3. Deploys using Stylus SDK
4. Gives you the contract address

### Manual Deployment

If you want more control:
```bash
# Build
cargo build --target wasm32-unknown-unknown --release

# Deploy
cargo stylus deploy \
  --private-key $PRIVATE_KEY \
  --endpoint https://sepolia-rollup.arbitrum.io/rpc
```

## Integration Patterns

### Basic Usage

```solidity
interface IMyPrecompile {
    function compute(bytes calldata input) external pure returns (bytes memory);
}

contract MyContract {
    IMyPrecompile constant precompile = IMyPrecompile(0x0100);
    
    function doSomething(bytes calldata data) external {
        bytes memory result = precompile.compute(data);
        // Use the result
    }
}
```

### Gas-Efficient Patterns

When you're doing multiple operations:
```solidity
contract BatchProcessor {
    function processBatch(bytes[] calldata inputs) external {
        for (uint i = 0; i < inputs.length; i++) {
            // Single call for all operations
            bytes memory result = precompile.compute(inputs[i]);
            // Process result
        }
    }
}
```

### Error Handling

Always check for failures:
```solidity
(bool success, bytes memory result) = address(precompile).staticcall(
    abi.encodeWithSelector(IPrecompile.compute.selector, input)
);
require(success, "Precompile failed");
```

## Performance Tips

### 1. Minimize Allocations

Bad:
```rust
let mut result = Vec::new();
for item in items {
    result.push(process(item));
}
```

Good:
```rust
let mut result = Vec::with_capacity(items.len());
for item in items {
    result.push(process(item));
}
```

### 2. Validate Early

Always validate inputs first:
```rust
pub fn compute(&self, input: &[u8]) -> Result<Vec<u8>, Error> {
    // Validate FIRST
    self.validate_input(input)?;
    
    // Then compute
    // ...
}
```

### 3. Use the Right Algorithm

Don't implement crypto yourself. Use established libraries:
- `sha2` for SHA256
- `blake2` for BLAKE2
- `poseidon-rs` for Poseidon

## Common Problems and Solutions

### WASM Binary Too Large

```
Error: WASM binary exceeds size limit
```

Fix: Optimize your build
```toml
[profile.release]
opt-level = "z"
lto = true
strip = true
```

### Tests Failing After Generation

Make sure you:
1. Added dependencies to Cargo.toml
2. Implemented all required functions
3. Used correct error types

### Deployment Fails

Check:
- You have enough ETH for gas
- Private key is correct
- Network RPC is accessible

## Real Examples

### Poseidon for ZK Merkle Trees

```solidity
contract ZKMerkleTree {
    IPoseidon constant poseidon = IPoseidon(0x0100);
    
    function verifyProof(
        uint256 leaf,
        uint256[] calldata proof,
        uint256 root
    ) external pure returns (bool) {
        uint256 hash = leaf;
        for (uint i = 0; i < proof.length; i++) {
            if (hash < proof[i]) {
                hash = poseidon.poseidon2(hash, proof[i]);
            } else {
                hash = poseidon.poseidon2(proof[i], hash);
            }
        }
        return hash == root;
    }
}
```

### SHA256 for Cross-Chain Verification

```solidity
contract CrossChainVerifier {
    ISha256 constant sha256 = ISha256(0x0102);
    
    function verifyBitcoinTransaction(
        bytes calldata txData,
        bytes32 expectedHash
    ) external view returns (bool) {
        bytes memory hash = sha256.sha256(txData);
        return bytes32(hash) == expectedHash;
    }
}
```

## The Bottom Line

This framework makes precompiles easy. You write the algorithm, we handle everything else.

Start with the template, add your logic, test it, deploy it. That's the whole process.

If you get stuck, the examples in `examples/` show complete implementations. The Poseidon one is particularly good if you're doing anything ZK-related.

Now go build something fast.

---

Need the theory? Check [Theory & Design](THEORY_AND_DESIGN.md). Having issues? See the [Testing Guide](TESTING_GUIDE.md).