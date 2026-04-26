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
  - `.bash_aliases`: Command shortcuts (currently commented out examples)
  - `.bash_functions`: Useful shell functions (`mkcd`, `extract`, `backup`, `d2u`)
  - `.bash_paths`: PATH management
  - `.bash_secrets`: Template for environment variables and API keys
  - `.bash_logger`: Logging library for scripts (source explicitly when needed)

- **Development Tools**: Setup scripts for popular development environments:
  - Git: Configuration, SSH key generation, and credential helper setup.
  - Java: Uses SDKMAN for version management. Installs Java (Temurin LTS) and Maven.
  - Python: Uses uv for version management, virtual environments, and dependency management.
  - Node.js: Uses nvm for version management. Also installs pnpm (via corepack) and TypeScript.
  - Bun: JavaScript runtime and toolkit (alternative to Node.js).
  - Go: Installs Go directly from the official website.
  - Rust: Uses rustup for toolchain management (rustc, cargo, clippy, rustfmt).
  - Neovim: Builds from source with LazyVim configuration. See [top Neovim configs](https://dotfyle.com/neovim/configurations/top) for inspiration.
- **AI Guidance**: Opinionated steering docs and a global AGENTS.md in `config/ai/` — copy into whichever AI coding tools you use.

- **Docker Support**: Optional installation of Docker and Docker Compose

## Setting Up Development Tools

After installing the dotfiles, you can set up development tools:

```bash
# For Git configuration and SSH keys
./tools/setup_git.sh

# For Java development with SDKMAN
./tools/setup_java.sh
source ~/.bashrc

# For Python development with uv
./tools/setup_python.sh
source ~/.bashrc

# For Node.js development with nvm
./tools/setup_node.sh
source ~/.bashrc

# For Bun development
./tools/setup_bun.sh
source ~/.bashrc

# For Go development
./tools/setup_golang.sh
source ~/.bashrc

# For Rust development
./tools/setup_rust.sh
source ~/.bashrc

# For Neovim with LazyVim
./tools/setup_nvim.sh
source ~/.bashrc
```

## How It Works

These dotfiles use a modular approach:

1. **Installation**: The `install.sh` script installs files to your home directory using either symlinks or copies
2. **Tool Configs**: Tool-specific configurations are stored in `bash/tool_configs/` and installed to `~/.tool_configs/`
3. **Setup Scripts**: One-time installation scripts in the `tools/` directory help set up development environments
4. **Secrets**: Sensitive information is stored in `~/.bash_secrets` (not tracked in git)

## Testing

This repo includes automated Docker-based testing and CI via GitHub Actions.

### Running Tests Locally

```bash
cd ~/dotfiles/test
chmod +x run-test.sh
./run-test.sh
```

This builds a fresh Ubuntu container, runs the full installation with `DOTFILES_CI=1`, then executes smoke tests that verify:

- Symlinks are created correctly (`.bashrc`, `.bash_aliases`, `.tmux.conf`)
- All tools are on PATH (`node`, `npm`, `java`, `python3`, `go`, `rustc`, `bun`, `nvim`, `pnpm`)
- All tools execute successfully (version checks)
- Node.js is visible to subprocesses (`env which node`, `bash -c "node --version"`)

### CI

GitHub Actions runs `test/run-test.sh` on every push and pull request to `main`.

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

### Common Issues and Troubleshooting

- **Permission denied errors**: Use `chmod +x` on scripts
- **Command not found**: Make sure to `source ~/.bashrc` after installation
- **Tool installation failures**: Check for missing dependencies in `packages/essentials.txt`
- **Path issues**: Verify the tool configs are being sourced correctly

## Customization

- Add your own aliases to `.bash_aliases`
- Add custom functions to `.bash_functions`
- Modify PATH settings in `.bash_paths`
- Modify AI guidance in `config/ai/AGENTS.md` and `config/ai/steering/`
- Store secrets and API keys in `.bash_secrets`

## Structure

```
dotfiles/
├── .github/
│   └── workflows/
│       └── test.yml            # CI pipeline (GitHub Actions)
├── bash/                       # Bash configuration files
│   ├── bashrc                  # Main bash configuration
│   ├── bash_aliases            # Command shortcuts (examples)
│   ├── bash_functions          # Custom shell functions
│   ├── bash_paths              # PATH management
│   ├── bash_secrets.template   # Template for secrets
│   ├── bash_logger             # Logging library for scripts
│   └── tool_configs/           # Tool-specific configurations
│       ├── bun.sh              # Bun configuration
│       ├── golang.sh           # Go configuration
│       ├── java.sh             # SDKMAN configuration
│       ├── node.sh             # nvm lazy-loading and Node.js PATH
│       ├── nvim.sh             # Neovim aliases (vi, vim)
│       ├── python.sh           # uv configuration
│       └── rust.sh             # Rust/Cargo configuration
├── config/                     # Application configurations
│   ├── nvim/                   # Neovim / LazyVim configuration
│   ├── ai/                     # AI coding tool guidance (copy into tools as needed)
│   │   ├── AGENTS.md           # Global AGENTS.md / CLAUDE.md template
│   │   └── steering/           # Opinionated steering docs (language, toolchain, style)
│   ├── tmux.conf               # Tmux configuration
│   └── vscode/                 # VS Code settings
│       ├── extensions.txt      # Recommended extensions
│       └── keybindings.json    # Custom keybindings
├── packages/                   # Package lists
│   └── essentials.txt          # Essential apt packages
├── test/                       # Docker-based testing
│   ├── Dockerfile              # Test container definition
│   ├── demo-bash-logger.sh     # Visual demo of bash_logger
│   └── run-test.sh             # Automated test runner
├── tools/                      # Setup scripts for development tools
│   ├── common.sh               # Shared bootstrapping (sources bash_logger)
│   ├── remove_nvim.sh          # Neovim uninstaller
│   ├── setup_bun.sh            # Installs Bun
│   ├── setup_git.sh            # Git config and SSH keys
│   ├── setup_golang.sh         # Installs Go
│   ├── setup_java.sh           # Installs SDKMAN, Java, and Maven
│   ├── setup_node.sh           # Installs nvm, Node.js, pnpm, TypeScript
│   ├── setup_nvim.sh           # Builds Neovim from source
│   ├── setup_python.sh         # Installs uv and Python
│   └── setup_rust.sh           # Installs Rust via rustup
├── install.sh                  # Main installation script
└── README.md                   # This file
```

## Maintenance

To update your dotfiles:

```bash
cd ~/dotfiles
git pull
./install.sh
```

This will update your configuration while preserving your personal settings in `.bash_secrets`.
