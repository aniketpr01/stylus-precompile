import { spawn } from "child_process";
import fs from "fs";
import path from "path";

async function deployWithRetry(maxRetries: number = 3): Promise<void> {
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
        console.log(`   PRIVATE_KEY=0x... npm run deploy:retry`);
        return;
    }

    // Alternative RPC endpoints to try - prioritize user's endpoint first
    const endpoints = [
        process.env.ARBITRUM_SEPOLIA_RPC, // User's custom endpoint first
        "https://sepolia-rollup.arbitrum.io/rpc", // Official endpoint
        "https://endpoints.omniatech.io/v1/arbitrum/sepolia/public",
        "https://arbitrum-sepolia.public.blastapi.io"
    ].filter(Boolean); // Remove undefined values

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        for (const endpoint of endpoints) {
            if (!endpoint) continue; // Skip if endpoint is undefined
            
            console.log(`\n🔄 Attempt ${attempt}/${maxRetries} with endpoint: ${endpoint}`);
            
            try {
                const success = await tryDeploy(endpoint, wasmPath);
                if (success) {
                    return; // Success, exit function
                }
            } catch (error) {
                const errorMessage = error instanceof Error ? error.message : String(error);
                console.log(`❌ Attempt failed: ${errorMessage}`);
                
                // If it's a rate limit error, wait longer before retrying
                if (errorMessage.includes("429") || errorMessage.includes("Too Many Requests")) {
                    const waitTime = attempt * 30000; // 30s, 60s, 90s
                    console.log(`⏳ Rate limited. Waiting ${waitTime/1000}s before retry...`);
                    await new Promise(resolve => setTimeout(resolve, waitTime));
                } else {
                    // For other errors, wait a shorter time
                    await new Promise(resolve => setTimeout(resolve, 5000));
                }
            }
        }
    }
    
    throw new Error(`Deployment failed after ${maxRetries} attempts with all endpoints`);
}

async function tryDeploy(endpoint: string, wasmPath: string): Promise<boolean> {
    return new Promise((resolve, reject) => {
        const deployArgs = [
            "stylus",
            "deploy",
            "--private-key", process.env.PRIVATE_KEY!,
            "--endpoint", endpoint,
            "--no-verify"
        ];

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
                
                resolve(true);
            } else {
                reject(new Error(`Exit code ${code}: ${errorOutput}`));
            }
        });

        child.on("error", (error) => {
            reject(new Error(`Process error: ${error.message}`));
        });
    });
}

deployWithRetry(3)
    .then(() => {
        console.log("\n🎉 Stylus deployment process completed successfully!");
        process.exit(0);
    })
    .catch((error) => {
        console.error("❌ Final deployment failure:", error.message);
        console.log("\n💡 Suggestions:");
        console.log("1. Wait a few minutes and try again (rate limiting)");
        console.log("2. Get your own RPC endpoint from Infura/Alchemy");
        console.log("3. Try deploying during off-peak hours");
        process.exit(1);
    });