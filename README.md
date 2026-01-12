# Please CLI by TNG Technology Consulting

An [AI helper script to create CLI commands](https://github.com/TNG/please-cli/).

## Usage

```bash
please <command description>
```

This will call Claude to generate a Linux command based on your input.

### Examples

![Demo](resources/demo.gif)

```bash
please list all files smaller than 1MB in the current folder, \
         sort them by size and show their name and line count
💡 Command:
  find . -maxdepth 1 -type f -size -1M -exec wc -l {} + | sort -n -k1'

❗ What should I do? [use arrow keys or initials to navigate]
> [I] Invoke   [C] Copy to clipboard   [Q] Ask a question   [A] Abort
```

You may then:

- Invoke the command directly (pressing I)
- Copy the command to the clipboard (pressing C)
- Ask a question about the command (pressing Q)
- Abort (pressing A)

```bash

### Parameters
- `-e` or `--explanation` will explain the command for you
- `-l` or `--legacy` will use Sonnet instead of Haiku
- `--debug` will display additional output
- `-m` or `--model` will specify the model (haiku, sonnet, opus)
- `-v` or `--version` will show the current version
- `-h` or `--help` will show the help message
```

## Installation

### brew

Using Homebrew (ugrades will be available via `brew upgrade please`)

```
brew tap TNG/please
brew install please
```

### apt

Using apt (upgrades will be available via `apt upgrade please`)

```bash
curl -sS https://tng.github.io/apt-please/public_key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/please.gpg > /dev/null
echo "deb https://tng.github.io/apt-please/ ./" | sudo tee -a /etc/apt/sources.list
sudo apt-get update

sudo apt-get install please
```

### nix

```bash
git clone https://github.com/TNG/please-cli.git
cd please-cli
nix-env -i -f .
```

Using Nix Flakes

```bash
nix run github:TNG/please-cli
```

### dpkg

Manual upgrades

```bash
wget https://tng.github.io/apt-please/please.deb
sudo dpkg -i please.deb
sudo apt-get install -f
```

### arch
The latest release is in the AUR under the name [please-cli](https://aur.archlinux.org/packages/please-cli). It can be installed [manually](https://wiki.archlinux.org/title/Arch_User_Repository) or with [a helper](https://wiki.archlinux.org/title/AUR_helpers).

#### Using an AUR helper (recommended)

With [yay](https://github.com/Jguer/yay):
```bash
yay -S please-cli
```

With [paru](https://github.com/Morganamilo/paru):
```bash
paru -S please-cli
```

#### Using aurutils

If you're using [aurutils](https://github.com/aurutils/aurutils) to manage AUR packages:

```bash
# First, ensure you have an aurutils repository set up
# If not, follow the aurutils setup instructions first

# Sync the AUR database and download the package
aur sync please-cli

# Install the package from your local repository
sudo pacman -S please-cli
```

#### Manual installation
Alternatively, you can build the package from source via
```bash
wget https://raw.githubusercontent.com/TNG/please-cli/main/PKGBUILD
makepkg --clean --install --syncdeps
```

### Manually from source

Just copying the script (manual upgrades)

```bash
wget https://raw.githubusercontent.com/TNG/please-cli/main/please.sh
sudo cp please.sh /usr/local/bin/please
sudo chmod +x /usr/local/bin/please

# Install xclip (Linux) for clipboard support
```

## Prerequisites

You need the Claude Code CLI installed and authenticated. Install it via:

```bash
npm install -g @anthropic-ai/claude-code
```

Then run `claude` once to authenticate with your Anthropic account.

## Configuration

You can use the following environment variable to change the default model:
* `PLEASE_CLAUDE_MODEL` - The model to use (default: `haiku`)

## Troubleshooting

If you receive the following error message:

```bash
Error: Claude Code CLI not found. Please install it first.
```

Make sure the Claude Code CLI is installed and available in your PATH. Run `claude --version` to verify.

## License

Please CLI is published under the Apache License 2.0, see http://www.apache.org/licenses/LICENSE-2.0 for details.

Copyright 2025 TNG Technology Consulting GmbH
