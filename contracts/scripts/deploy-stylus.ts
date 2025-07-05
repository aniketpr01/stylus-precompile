import { spawn } from "child_process";
import fs from "fs";
import path from "path";

async function main() {
    console.log("🚀 Deploying Poseidon Precompile to Arbitrum Sepolia using Stylus CLI...");

    // Check if WASM file exists
    const wasmPath = path.join(__dirname, "../../target/wasm32-unknown-unknown/release/precompile.wasm");
    
    if (!fs.existsSync(wasmPath)) {
        throw new Error(`WASM file not found at ${wasmPath}. Run: cargo build --target wasm32-unknown-unknown --release`);
    }

    const wasmBytecode = fs.readFileSync(wasmPath);
    console.log(`📦 WASM size: ${wasmBytecode.length} bytes (${(wasmBytecode.length / 1024).toFixed(2)} KB)`);

    // Check if private key is provided
    if (!process.env.PRIVATE_KEY) {
        console.log("⚠️  PRIVATE_KEY environment variable not set.");
        console.log("📋 To deploy, run:");
        console.log(`   PRIVATE_KEY=0x... npm run deploy:stylus`);
        console.log("Or use cargo stylus directly:");
        console.log(`   cargo stylus deploy --private-key=0x... --endpoint=${process.env.ARBITRUM_SEPOLIA_RPC || "https://sepolia-rollup.arbitrum.io/rpc"}`);
        return;
    }

    // Use alternative RPC endpoints to avoid rate limiting
    const endpoints = [
        process.env.ARBITRUM_SEPOLIA_RPC,
        "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
        "https://sepolia-rollup.arbitrum.io/rpc",
        "https://arbitrum-sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161"
    ].filter(Boolean);
    
    const endpoint = endpoints[0] || "https://arbitrum-sepolia.blockpi.network/v1/rpc/public";
    
    const deployArgs = [
        "stylus",
        "deploy",
        "--private-key", process.env.PRIVATE_KEY,
        "--endpoint", endpoint,
        "--no-verify"  // Skip Docker verification to avoid Docker issues
    ];

    console.log("🔨 Running cargo stylus deploy (without Docker verification)...");
    console.log(`📡 Endpoint: ${endpoint}`);
    console.log("⏳ This may take a few minutes due to RPC rate limits...");
    
    return new Promise((resolve, reject) => {
        let output = "";
        let errorOutput = "";
        
        const child = spawn("cargo", deployArgs, {
            cwd: path.join(__dirname, "../.."),
            stdio: ["inherit", "pipe", "pipe"]
        });

        child.stdout.on("data", (data) => {
            const text = data.toString();
            output += text;
            process.stdout.write(text);
        });

        child.stderr.on("data", (data) => {
            const text = data.toString();
            errorOutput += text;
            process.stderr.write(text);
        });

        child.on("close", (code) => {
            if (code === 0) {
                console.log("\n✅ Deployment completed successfully!");
                
                // Try to extract contract address from output
                const addressMatch = output.match(/deployed code at address (0x[a-fA-F0-9]{40})/);
                if (addressMatch) {
                    const contractAddress = addressMatch[1];
                    console.log(`📍 Contract deployed at: ${contractAddress}`);
                    
                    // Save deployment info
                    const deploymentInfo = {
                        address: contractAddress,
                        network: "arbitrum-sepolia",
                        endpoint: endpoint,
                        timestamp: new Date().toISOString(),
                        wasmSize: fs.readFileSync(wasmPath).length
                    };
                    
                    const deploymentsDir = path.join(__dirname, "../deployments");
                    if (!fs.existsSync(deploymentsDir)) {
                        fs.mkdirSync(deploymentsDir, { recursive: true });
                    }
                    
                    fs.writeFileSync(
                        path.join(deploymentsDir, "poseidon-precompile.json"),
                        JSON.stringify(deploymentInfo, null, 2)
                    );
                    
                    console.log("📄 Deployment info saved to deployments/poseidon-precompile.json");
                }
                
                resolve(code);
            } else {
                reject(new Error(`Deployment failed with exit code ${code}. Error: ${errorOutput}`));
            }
        });

        child.on("error", (error) => {
            reject(new Error(`Failed to start deployment: ${error.message}`));
        });
    });
}

main()
    .then(() => {
        console.log("\n🎉 Stylus deployment process completed!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Deployment failed:", error.message);
        process.exit(1);
    });