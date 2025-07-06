# Quick Reference

Just the commands you need, nothing else.

## Deploy Poseidon

```bash
# Set your RPC and private key
export ARBITRUM_SEPOLIA_RPC=https://arb-sepolia.g.alchemy.com/v2/YOUR_API_KEY
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# Deploy with retry (in case of network issues)
npm run deploy:retry
```

## Test It

```bash
# Run the gas benchmarks on Sepolia
npm test -- --network arbitrumSepolia --grep "Poseidon Precompile Gas Benchmarks"
```

That's it. The precompile should show 93% gas savings compared to Solidity.