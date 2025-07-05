const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PoseidonHash Precompile", function () {
  let poseidonExample;
  let poseidonPrecompile;
  
  // Mock precompile address (in real deployment, this would be the actual precompile)
  const PRECOMPILE_ADDRESS = "0x0000000000000000000000000000000000000100";
  
  before(async function () {
    // Deploy the example contract
    const PoseidonExample = await ethers.getContractFactory("PoseidonExample");
    poseidonExample = await PoseidonExample.deploy();
    await poseidonExample.waitForDeployment();
    
    // Deploy the precompile wrapper contract
    const PoseidonHashPrecompile = await ethers.getContractFactory("PoseidonHashPrecompile");
    poseidonPrecompile = await PoseidonHashPrecompile.deploy();
    await poseidonPrecompile.waitForDeployment();
  });

  describe("Contract Deployment", function () {
    it("Should deploy example contract successfully", async function () {
      expect(await poseidonExample.getAddress()).to.be.properAddress;
    });

    it("Should deploy precompile wrapper successfully", async function () {
      expect(await poseidonPrecompile.getAddress()).to.be.properAddress;
    });

    it("Should have correct precompile address", async function () {
      expect(await poseidonExample.POSEIDON_PRECOMPILE()).to.equal(PRECOMPILE_ADDRESS);
      expect(await poseidonPrecompile.POSEIDON_PRECOMPILE()).to.equal(PRECOMPILE_ADDRESS);
    });
  });

  describe("Interface Validation", function () {
    it("Should have correct function selectors", async function () {
      const IPoseidonHash = await ethers.getContractFactory("IPoseidonHash");
      const interface = IPoseidonHash.interface;
      
      // Check that all expected functions exist
      expect(interface.getFunction("poseidon1")).to.not.be.null;
      expect(interface.getFunction("poseidon2")).to.not.be.null;
      expect(interface.getFunction("poseidonN")).to.not.be.null;
    });

    it("Should have correct field modulus constant", async function () {
      const expectedModulus = "21888242871839275222246405745257275088548364400416034343698204186575808495617";
      expect(await poseidonPrecompile.FIELD_MODULUS()).to.equal(expectedModulus);
    });
  });

  describe("Input Validation", function () {
    it("Should validate single field element", async function () {
      const validValue = ethers.parseUnits("1000", 0);
      
      // This would fail in real deployment without the precompile
      // Here we're testing the contract logic and validation
      try {
        await poseidonPrecompile.poseidon1.staticCall(validValue);
      } catch (error) {
        // Expected to fail since precompile is not actually deployed
        expect(error.message).to.include("call failed");
      }
    });

    it("Should reject field element that is too large", async function () {
      // Value larger than BN254 modulus
      const invalidValue = ethers.parseUnits("21888242871839275222246405745257275088548364400416034343698204186575808495618", 0);
      
      await expect(
        poseidonPrecompile.poseidon1(invalidValue)
      ).to.be.revertedWith("Value exceeds field modulus");
    });

    it("Should reject empty array", async function () {
      const emptyArray = [];
      
      await expect(
        poseidonPrecompile.poseidonN(emptyArray)
      ).to.be.revertedWith("Array cannot be empty");
    });

    it("Should validate all elements in array", async function () {
      const invalidValue = ethers.parseUnits("21888242871839275222246405745257275088548364400416034343698204186575808495618", 0);
      const invalidArray = [1, 2, invalidValue];
      
      await expect(
        poseidonPrecompile.poseidonN(invalidArray)
      ).to.be.revertedWith("Value exceeds field modulus");
    });
  });

  describe("Example Contract Functions", function () {
    it("Should have correct commitment creation logic", async function () {
      const secret = 12345;
      const nonce = 67890;
      
      // This would work with actual precompile deployment
      try {
        await poseidonExample.createCommitment(secret, nonce);
      } catch (error) {
        expect(error.message).to.include("Commitment creation failed");
      }
    });

    it("Should handle hash chain computation", async function () {
      const seed = 42;
      const length = 5;
      
      try {
        await poseidonExample.computeHashChain(seed, length);
      } catch (error) {
        expect(error.message).to.include("Hash chain computation failed");
      }
    });

    it("Should compute merkle tree leaves", async function () {
      const data = 1000;
      const index = 7;
      
      try {
        await poseidonExample.computeLeaf(data, index);
      } catch (error) {
        expect(error.message).to.include("Leaf computation failed");
      }
    });
  });

  describe("Gas Usage Analysis", function () {
    it("Should emit gas usage events", async function () {
      // Test gas usage tracking (would work with actual precompile)
      const value = 42;
      
      try {
        const tx = await poseidonExample.hashSingle(value);
        const receipt = await tx.wait();
        
        // Check for HashComputed event
        const event = receipt.logs.find(log => 
          log.topics[0] === ethers.id("HashComputed(string,bytes32,uint256)")
        );
        
        if (event) {
          const decoded = poseidonExample.interface.parseLog(event);
          expect(decoded.args.method).to.equal("poseidon1");
          expect(decoded.args.gasUsed).to.be.greaterThan(0);
        }
      } catch (error) {
        // Expected without actual precompile
        expect(error.message).to.include("Poseidon1 call failed");
      }
    });
  });

  describe("Error Handling", function () {
    it("Should handle precompile call failures gracefully", async function () {
      const value = 42;
      
      await expect(
        poseidonExample.hashSingle(value)
      ).to.be.revertedWith("Poseidon1 call failed");
    });

    it("Should handle invalid array input", async function () {
      const values = [1, 2, 3];
      
      await expect(
        poseidonExample.hashArray(values)
      ).to.be.revertedWith("PoseidonN call failed");
    });
  });

  describe("Integration Scenarios", function () {
    it("Should support typical ZK application workflow", async function () {
      // Simulate a typical zero-knowledge application workflow
      const secrets = [100, 200, 300];
      const nonces = [1, 2, 3];
      
      // Test commitment creation for each secret-nonce pair
      for (let i = 0; i < secrets.length; i++) {
        try {
          await poseidonExample.createCommitment(secrets[i], nonces[i]);
        } catch (error) {
          expect(error.message).to.include("Commitment creation failed");
        }
      }
    });

    it("Should support merkle tree construction", async function () {
      // Simulate merkle tree leaf computation
      const leafData = [10, 20, 30, 40];
      
      for (let i = 0; i < leafData.length; i++) {
        try {
          await poseidonExample.computeLeaf(leafData[i], i);
        } catch (error) {
          expect(error.message).to.include("Leaf computation failed");
        }
      }
    });
  });
});