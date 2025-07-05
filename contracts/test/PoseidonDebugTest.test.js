const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Poseidon Precompile Debug Test", function () {
    it("should check if precompile is deployed", async function () {
        const precompileAddress = "0xca466489bb94f76f731342df984e8fdfb89102ea";
        
        console.log("🔍 Checking precompile deployment...");
        
        // Check if there's code at the address
        const code = await ethers.provider.getCode(precompileAddress);
        console.log(`📦 Code at ${precompileAddress}:`, code);
        console.log(`📏 Code length: ${code.length} characters`);
        
        if (code === "0x") {
            console.log("❌ No code found at precompile address!");
        } else {
            console.log("✅ Code found at precompile address");
        }
        
        // Check balance
        const balance = await ethers.provider.getBalance(precompileAddress);
        console.log(`💰 Balance: ${ethers.formatEther(balance)} ETH`);
        
        // Try a simple call to see what happens
        try {
            const result = await ethers.provider.call({
                to: precompileAddress,
                data: "0x12345678" // Random data to see what error we get
            });
            console.log("📞 Random call result:", result);
        } catch (error) {
            console.log("❌ Random call error:", error.message);
        }
        
        // Try calling with correct selector but wrong data
        try {
            // poseidon1 selector but empty data
            const selector = ethers.id("poseidon1(uint256)").slice(0, 10);
            console.log("🎯 Using poseidon1 selector:", selector);
            
            const result = await ethers.provider.call({
                to: precompileAddress,
                data: selector
            });
            console.log("📞 Selector-only call result:", result);
        } catch (error) {
            console.log("❌ Selector-only call error:", error.message);
        }
        
        // Try with proper encoded data
        try {
            const iface = new ethers.Interface([
                "function poseidon1(uint256 input) external pure returns (uint256 hash)"
            ]);
            const calldata = iface.encodeFunctionData("poseidon1", [42]);
            console.log("🎯 Full calldata:", calldata);
            console.log("🎯 Calldata length:", calldata.length);
            
            const result = await ethers.provider.call({
                to: precompileAddress,
                data: calldata
            });
            console.log("📞 Full call result:", result);
        } catch (error) {
            console.log("❌ Full call error:", error.message);
        }
    });
});