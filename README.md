# Dotfiles

My personal bash configuration files and development environment setup.

## Installation

```bash
git clone https://github.com/perryrobinson/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

## What's Included

- **Bash Configuration**: Modular setup with separate files for different aspects of configuration:
  - `.bashrc`: Main configuration file
  - `.bash_aliases`: Command shortcuts (currently commented out)
  - `.bash_functions`: Useful shell functions
  - `.bash_paths`: PATH management
  - `.bash_secrets`: Template for environment variables and API keys

- **Development Tools**: Setup scripts for popular development environments:
  - Java: Uses SDKMAN for version management
  - Python: Uses pyenv for version management
  - Node.js: Uses nvm for version management

- **Docker Support**: Optional installation of Docker and Docker Compose

## Setting Up Development Tools

After installing the dotfiles, you can set up development tools:

```bash
# For Java development with SDKMAN
./tools/setup_java.sh
source ~/.bashrc

# For Python development with pyenv
./tools/setup_python.sh
source ~/.bashrc

# For Node.js development with nvm
./tools/setup_node.sh
source ~/.bashrc
```

## How It Works

These dotfiles use a modular approach:

1. **Installation**: The `install.sh` script creates symlinks from this repository to your home directory
2. **Tool Configs**: Tool-specific configurations are stored in `bash/tool_configs/` and linked to `~/.tool_configs/`
3. **Setup Scripts**: One-time installation scripts in the `tools/` directory help set up development environments
4. **Secrets**: Sensitive information is stored in `~/.bash_secrets` (not tracked in git)

## Testing Environment

This repo includes Docker-based testing to verify the dotfiles work correctly:

```bash
cd ~/dotfiles/test
./run-test.sh
```

This launches a fresh Ubuntu container with the dotfiles mounted, allowing you to test installation and setup without affecting your actual system.

## Customization

- Add your own aliases to `.bash_aliases`
- Add custom functions to `.bash_functions`
- Modify PATH settings in `.bash_paths`
- Store secrets and API keys in `.bash_secrets`

## Structure

```
dotfiles/
├── bash/                   # Bash configuration files
│   ├── bashrc              # Main bash configuration
│   ├── bash_aliases        # Command shortcuts
│   ├── bash_functions      # Custom shell functions
│   ├── bash_paths          # PATH management
│   ├── bash_secrets.template  # Template for secrets
│   └── tool_configs/       # Tool-specific configurations
│       ├── java.sh         # SDKMAN configuration
│       ├── python.sh       # pyenv configuration
│       └── node.sh         # nvm configuration
├── tools/                  # Setup scripts for development tools
│   ├── setup_java.sh       # Installs SDKMAN and Java
│   ├── setup_python.sh     # Installs pyenv and Python
│   └── setup_node.sh       # Installs nvm and Node.js
├── test/                   # Docker-based testing environment
│   ├── Dockerfile          # Test container definition
│   ├── docker-compose.yml  # Container orchestration
│   └── run-test.sh         # Test runner script
├── packages/               # Package lists
│   └── essentials.txt      # Essential packages to install
├── install.sh              # Main installation script
└── README.md               # Documentation
```

## Maintenance

To update your dotfiles:

```bash
cd ~/dotfiles
git pull
./install.sh
```

This will update your configuration while preserving your personal settings in `.bash_secrets`.