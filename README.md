# Dotfiles

My personal bash configuration files and development environment setup.

## Installation

```bash
git clone https://github.com/perryrobinson/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

During installation, you'll be prompted to choose between two installation methods:

1. **Symlinks (Recommended for git tracking)**
   - Creates symbolic links from your home directory to the repository files
   - Changes made in your home directory will affect the repository
   - Good for development and tracking changes
   - Allows for easy updates and version control

2. **Copies (Recommended for local-only changes)**
   - Copies files from the repository to your home directory
   - Changes made in your home directory won't affect the repository
   - Good for personal use and local customizations
   - Provides isolation from repository changes

## What's Included

- **Bash Configuration**: Modular setup with separate files for different aspects of configuration:
  - `.bashrc`: Main configuration file
  - `.bash_aliases`: Command shortcuts (currently commented out)
  - `.bash_functions`: Useful shell functions
  - `.bash_paths`: PATH management
  - `.bash_secrets`: Template for environment variables and API keys

- **Development Tools**: Setup scripts for popular development environments:
  - Java: Uses SDKMAN for version management TODO add maven and have it configured properly with sdkman.
  - Python: Uses pyenv for version management. TODO add poetry or uv. Also look at replacing pyenv/poetry with uv.
  - Node.js: Uses nvm for version management. Also installs yarn.
  - Go: Installs Go directly from the official website.

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

# For Go development
./tools/setup_golang.sh
source ~/.bashrc
```

## How It Works

These dotfiles use a modular approach:

1. **Installation**: The `install.sh` script installs files to your home directory using either symlinks or copies
2. **Tool Configs**: Tool-specific configurations are stored in `bash/tool_configs/` and installed to `~/.tool_configs/`
3. **Setup Scripts**: One-time installation scripts in the `tools/` directory help set up development environments
4. **Secrets**: Sensitive information is stored in `~/.bash_secrets` (not tracked in git)

## Testing Environment

This repo includes Docker-based testing to verify the dotfiles work correctly.

### Running the Test Environment

Start the test environment:

```bash
cd ~/dotfiles/test
chmod +x run-test.sh
./run-test.sh
```

This launches a fresh Ubuntu container with the dotfiles mounted at `/home/testuser/dotfiles`.

### Testing the Installation

Once inside the container, follow these steps to test your dotfiles:

```bash
# Make scripts executable (needed because permissions aren't preserved in Docker volumes)
cd ~/dotfiles
chmod +x install.sh
chmod +x tools/*.sh

# Run the installation script
./install.sh

# Source the new bashrc to apply changes
source ~/.bashrc

# Verify symlinks were created
ls -la ~ | grep bash
# You should see symlinks to your dotfiles repo

# Verify secrets file was created
cat ~/.bash_secrets
# You can edit this file to test environment variables
```

### Testing Development Tools

Test each development environment setup:

```bash
# Test Java setup with SDKMAN
./tools/setup_java.sh
source ~/.bashrc
sdk version  # Should display SDKMAN version
java --version

# Test Python setup with pyenv
./tools/setup_python.sh
source ~/.bashrc
pyenv --version  # Should display pyenv version
python --version

# Test Node.js setup with nvm
./tools/setup_node.sh
source ~/.bashrc
nvm --version  # Should display nvm version
npm --version
yarn --version
node --version

# Test Go setup
./tools/setup_golang.sh
source ~/.bashrc
go version  # Should display Go version
```

### Verifying Tool Configurations

Verify that tool-specific configurations are working:

```bash
# Check if .tool_configs directory was created
ls -la ~/.tool_configs

# Check if PATH is set up correctly for each tool
echo $PATH | grep sdkman
echo $PATH | grep pyenv
echo $PATH | grep nvm
echo $PATH | grep "/usr/local/go/bin" # Check for Go
echo $PATH | grep "$HOME/go/bin"    # Check for Go's GOPATH bin

# Try installing a specific version of a tool
sdk install java 17.0.8-tem
pyenv install 3.10.0
nvm install 16
```

### Testing Bash Functions

Test the bash functions to ensure they work correctly:

```bash
# Test mkcd function
mkcd test-dir
pwd  # Should show you're in the new directory

# Test extract function (if you have a test archive)
extract test-archive.zip

# Test backup function
echo "test" > testfile
backup testfile
ls -la  # Should show a backup file with timestamp
```

### Exiting the Test Environment

When you're done testing, simply type:

```bash
exit
```

This will exit the container, stop it automatically, and remove all images/volumes/orphans.

### Common Issues and Troubleshooting

- **Permission denied errors**: Use `chmod +x` on scripts
- **Command not found**: Make sure to `source ~/.bashrc` after installation
- **Tool installation failures**: Check for missing dependencies in your essentials.txt
- **Path issues**: Verify the tool configs are being sourced correctly

Use this testing environment to make changes to your dotfiles and immediately see how they work before committing them to your repository.

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
│       ├── node.sh         # nvm configuration
│       └── golang.sh       # Go configuration
├── tools/                  # Setup scripts for development tools
│   ├── setup_java.sh       # Installs SDKMAN and Java
│   ├── setup_python.sh     # Installs pyenv and Python
│   ├── setup_node.sh       # Installs nvm and Node.js
│   └── setup_golang.sh     # Installs Go
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

## Next Steps

### Python - replacing pyenv and poetry with uv

uv has the potential to replace both pyenv and poetry, worth exploring it. but uv must be installed as the standalone tool instead of just as a python dependency

Install uv as the standalone tool

```bash
# download the uv standalone
curl -LsSf https://astral.sh/uv/install.sh | sh

# add this to your .bash_paths
# uv
export PATH="$HOME/.cargo/bin:$PATH"
```

Using uv for Python version management (replacing pyenv)
Now you can use uv to manage Python versions:

```bash
# Install a specific Python version
uv python install 3.12

# Pin global python verison
uv python pin --global <version>

# Use a specific Python version
uv python use 3.12

# Pin repository level python version
uv python pin <version>

# Create a virtual environment with a specific Python version
uv venv --python 3.12
```

Using uv for dependency management (replacing poetry)
For dependency management similar to poetry:

```bash
# Initialize a new project (creates pyproject.toml)
uv init

# Add dependencies
uv pip add numpy pandas

# Add dev dependencies
uv pip add --dev pytest black

# Install all dependencies from pyproject.toml
uv pip sync
```

### Neovim

https://dotfyle.com/neovim/configurations/top
