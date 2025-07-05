const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Poseidon Precompile Direct Test", function () {
    let precompileAddress;

    before(async function () {
        console.log("🚀 Setting up direct precompile test...");
        
        // Check the network we're running on
        const network = await ethers.provider.getNetwork();
        
        if (network.chainId === 421614n) {
            // Use deployed precompile on Arbitrum Sepolia
            precompileAddress = "0xca466489bb94f76f731342df984e8fdfb89102ea";
            console.log("📡 Testing deployed precompile at:", precompileAddress);
        } else {
            console.log("❌ This test only works on Arbitrum Sepolia");
            this.skip();
        }
    });

    describe("Direct Precompile Calls", function () {
        it("should call poseidon1 directly", async function () {
            const input = 42;
            
            // Encode the function call
            const iface = new ethers.Interface([
                "function poseidon1(uint256 input) external pure returns (uint256 hash)"
            ]);
            const calldata = iface.encodeFunctionData("poseidon1", [input]);
            
            try {
                // Make a static call to the precompile
                const result = await ethers.provider.call({
                    to: precompileAddress,
                    data: calldata
                });
                
                // Decode the result
                const decoded = iface.decodeFunctionResult("poseidon1", result);
                const hash = decoded[0];
                
                console.log(`📊 poseidon1(${input}) = ${hash}`);
                expect(hash).to.not.equal(0);
                
            } catch (error) {
                console.error("❌ poseidon1 call failed:", error.message);
                throw error;
            }
        });

        it("should call poseidon2 directly", async function () {
            const left = 100;
            const right = 200;
            
            // Encode the function call
            const iface = new ethers.Interface([
                "function poseidon2(uint256 left, uint256 right) external pure returns (uint256 hash)"
            ]);
            const calldata = iface.encodeFunctionData("poseidon2", [left, right]);
            
            try {
                // Make a static call to the precompile
                const result = await ethers.provider.call({
                    to: precompileAddress,
                    data: calldata
                });
                
                // Decode the result
                const decoded = iface.decodeFunctionResult("poseidon2", result);
                const hash = decoded[0];
                
                console.log(`📊 poseidon2(${left}, ${right}) = ${hash}`);
                expect(hash).to.not.equal(0);
                
            } catch (error) {
                console.error("❌ poseidon2 call failed:", error.message);
                throw error;
            }
        });

        it("should call poseidonN directly", async function () {
            const inputs = [1, 2, 3];
            
            // Encode the function call
            const iface = new ethers.Interface([
                "function poseidonN(uint256[] inputs) external pure returns (uint256 hash)"
            ]);
            const calldata = iface.encodeFunctionData("poseidonN", [inputs]);
            
            try {
                // Make a static call to the precompile
                const result = await ethers.provider.call({
                    to: precompileAddress,
                    data: calldata
                });
                
                // Decode the result
                const decoded = iface.decodeFunctionResult("poseidonN", result);
                const hash = decoded[0];
                
                console.log(`📊 poseidonN([${inputs.join(', ')}]) = ${hash}`);
                expect(hash).to.not.equal(0);
                
            } catch (error) {
                console.error("❌ poseidonN call failed:", error.message);
                throw error;
            }
        });

        it("should estimate gas usage", async function () {
            const input = 42;
            
            // Encode the function call
            const iface = new ethers.Interface([
                "function poseidon1(uint256 input) external pure returns (uint256 hash)"
            ]);
            const calldata = iface.encodeFunctionData("poseidon1", [input]);
            
            try {
                // Estimate gas
                const gasEstimate = await ethers.provider.estimateGas({
                    to: precompileAddress,
                    data: calldata
                });
                
                console.log(`⛽ poseidon1 gas estimate: ${gasEstimate}`);
                expect(gasEstimate).to.be.greaterThan(0);
                expect(gasEstimate).to.be.lessThan(100000); // Should be much less than 100k gas
                
            } catch (error) {
                console.error("❌ Gas estimation failed:", error.message);
                throw error;
            }
        });
    });
});