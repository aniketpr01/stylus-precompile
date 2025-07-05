import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

async function main() {
    console.log("🚀 Deploying Poseidon Precompile to Arbitrum Sepolia...");

    const signers = await ethers.getSigners();
    if (signers.length === 0) {
        throw new Error("No signers available. Please set PRIVATE_KEY environment variable.");
    }
    
    const deployer = signers[0];
    console.log("Deploying with account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider!.getBalance(deployer.address)));

    // Read WASM bytecode
    const wasmPath = path.join(__dirname, "../../target/wasm32-unknown-unknown/release/precompile.wasm");

    if (!fs.existsSync(wasmPath)) {
        throw new Error(`WASM file not found at ${wasmPath}. Run: cargo build --target wasm32-unknown-unknown --release --features stylus`);
    }

    const wasmBytecode = fs.readFileSync(wasmPath);
    console.log(`📦 WASM size: ${wasmBytecode.length} bytes (${(wasmBytecode.length / 1024).toFixed(2)} KB)`);

    // For Stylus deployment, we need to use cargo stylus deploy
    console.log("⚠️  Note: Direct WASM deployment via Hardhat is not supported for Stylus.");
    console.log("📋 Use the following command to deploy:");
    console.log(`   cargo stylus deploy --private-key=${process.env.PRIVATE_KEY || "0x..."} --endpoint=${process.env.ARBITRUM_SEPOLIA_RPC || "https://sepolia-rollup.arbitrum.io/rpc"}`);
    console.log("📋 Or use the new Stylus deployment script:");
    console.log(`   npm run deploy:stylus`);
    
    throw new Error("Please use 'cargo stylus deploy' for Stylus contract deployment. Use the deploy-stylus.ts script instead.");
}

main()
    .then((address) => {
        console.log(`\n🎉 Deployment complete! Precompile address: ${address}`);
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    });
