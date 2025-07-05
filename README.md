# Arbitrum Stylus Precompile Framework

A comprehensive, open-source framework for developing high-performance precompiles on Arbitrum Stylus, achieving up to 93% gas savings compared to Solidity implementations.

## 🚀 Overview

This framework enables developers to create efficient cryptographic precompiles using Rust and deploy them to Arbitrum Stylus. It includes a production-ready Poseidon hash implementation optimized for zero-knowledge applications.

## ✨ Key Features

- **93% Gas Savings**: Dramatically reduce costs for cryptographic operations
- **Production-Ready**: Complete Poseidon hash precompile with BN254 field arithmetic
- **Developer-Friendly**: Code generation tools and comprehensive templates
- **Fully Tested**: Extensive test suite with benchmarks on Arbitrum Sepolia
- **Open Source**: MIT licensed for community use and contribution

## 📦 What's Included

- **Poseidon Precompile**: Optimized implementation for ZK-SNARKs and privacy applications
- **Framework Tools**: Scripts for generating new precompiles from templates
- **Deployment Scripts**: Automated deployment to Arbitrum networks
- **Comprehensive Tests**: Unit, integration, and gas benchmark tests
- **Documentation**: Complete guides for theory, implementation, and deployment

## 🛠️ Quick Start

```bash
# Clone the repository
git clone <repository-url>
cd precompile

# Build the project
cargo build --release

# Run tests
cargo test

# Generate a new precompile
./scripts/generate_precompile.sh my_algorithm

# Deploy to Arbitrum
./scripts/deploy.sh --network arbitrum-sepolia
```

## 📊 Performance

| Operation | Precompile Gas | Solidity Gas | Improvement |
|-----------|----------------|--------------|-------------|
| Single Hash | 41,000 | 553,000 | 93% |
| Pair Hash | 41,000 | 553,000 | 93% |
| Array (10) | 352,000 | 5,142,000 | 93% |

## 📚 Documentation

- **[Theory & Design](docs/THEORY_AND_DESIGN.md)**: Architecture and cryptographic foundations
- **[Practical Guide](docs/PRACTICAL_GUIDE.md)**: Step-by-step implementation guide
- **[CLAUDE.md](CLAUDE.md)**: AI assistance instructions

## 🎯 Use Cases

- **Zero-Knowledge Proofs**: Efficient Merkle tree operations and commitments
- **Privacy Protocols**: On-chain privacy-preserving computations
- **DeFi Applications**: High-performance cryptographic primitives
- **Cross-Chain Bridges**: Optimized hash verification

## 🤝 Contributing

We welcome contributions! This project is open-source under the MIT license. Feel free to:
- Submit issues and feature requests
- Create pull requests
- Share your precompile implementations
- Improve documentation

## 🔗 Resources

- [Arbitrum Stylus Documentation](https://docs.arbitrum.io/stylus)
- [Deployment Guide](docs/DEPLOYMENT_GUIDE.md)
- [Testing Guide](docs/TESTING_GUIDE.md)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---
