// Main entry point for both deployment runner and CLI

#[cfg(feature = "cli")]
use precompile::cli;

fn main() {
    #[cfg(feature = "cli")]
    {
        if let Err(e) = cli::run() {
            eprintln!("Error: {}", e);
            std::process::exit(1);
        }
    }
    
    #[cfg(not(feature = "cli"))]
    {
        println!("Stylus precompile deployment binary");
    }
}