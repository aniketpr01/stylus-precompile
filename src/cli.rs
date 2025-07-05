//! CLI implementation for stylus-forge
//! 
//! Provides command-line interface for generating and managing precompiles.

use clap::{Parser, Subcommand};
use colored::*;
use std::process::Command;
use anyhow::Result;

#[derive(Parser)]
#[command(name = "stylus-forge")]
#[command(about = "A CLI tool for creating and managing Arbitrum Stylus precompiles", long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Generate a new precompile from template
    Generate {
        /// Name of the precompile (e.g., sha256, blake2)
        name: String,
        
        /// Description of the precompile
        #[arg(short, long, default_value = "A new precompile implementation")]
        description: String,
    },
    
    /// Build the project
    Build {
        /// Build for release
        #[arg(short, long)]
        release: bool,
    },
    
    /// Run tests
    Test {
        /// Test name pattern
        pattern: Option<String>,
    },
    
    /// Deploy to Arbitrum Stylus
    Deploy {
        /// Network to deploy to
        #[arg(short, long)]
        network: String,
        
        /// Private key for deployment
        #[arg(short, long)]
        private_key: Option<String>,
    },
}

pub fn run() -> Result<()> {
    let cli = Cli::parse();
    
    match cli.command {
        Commands::Generate { name, description } => {
            println!("{}", "🔨 Generating new precompile...".bright_blue());
            
            // Run the generate script
            let status = Command::new("bash")
                .arg("scripts/generate_precompile.sh")
                .arg(&name)
                .arg(&description)
                .status()?;
                
            if status.success() {
                println!("{}", format!("✅ Successfully generated {} precompile!", name).bright_green());
            } else {
                println!("{}", "❌ Failed to generate precompile".bright_red());
            }
        }
        
        Commands::Build { release } => {
            println!("{}", "🔨 Building project...".bright_blue());
            
            let mut cmd = Command::new("cargo");
            cmd.arg("build")
                .arg("--target")
                .arg("wasm32-unknown-unknown");
                
            if release {
                cmd.arg("--release");
            }
            
            let status = cmd.status()?;
            
            if status.success() {
                println!("{}", "✅ Build successful!".bright_green());
            } else {
                println!("{}", "❌ Build failed".bright_red());
            }
        }
        
        Commands::Test { pattern } => {
            println!("{}", "🧪 Running tests...".bright_blue());
            
            let mut cmd = Command::new("cargo");
            cmd.arg("test");
            
            if let Some(p) = pattern {
                cmd.arg(&p);
            }
            
            let status = cmd.status()?;
            
            if status.success() {
                println!("{}", "✅ All tests passed!".bright_green());
            } else {
                println!("{}", "❌ Some tests failed".bright_red());
            }
        }
        
        Commands::Deploy { network, private_key } => {
            println!("{}", format!("🚀 Deploying to {}...", network).bright_blue());
            
            let mut cmd = Command::new("bash");
            cmd.arg("scripts/deploy.sh")
                .arg("--network")
                .arg(&network);
                
            if let Some(key) = private_key {
                cmd.arg("--private-key")
                    .arg(&key);
            }
            
            let status = cmd.status()?;
            
            if status.success() {
                println!("{}", "✅ Deployment successful!".bright_green());
            } else {
                println!("{}", "❌ Deployment failed".bright_red());
            }
        }
    }
    
    Ok(())
}