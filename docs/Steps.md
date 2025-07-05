# Poseidon Precompile Gas Benchmarks

## Deployment Steps

```
ARBITRUM_SEPOLIA_RPC=https://arb-sepolia.g.alchemy.com/v2/lnKrZEPbFom7fm2TJURI8 PRIVATE_KEY=0x0000000000000000000000000000000000000000000000000000000000000000 npm run deploy:retry
```

## Test Steps

```
npm test -- --network arbitrumSepolia --grep "Poseidon Precompile Gas Benchmarks"
```
