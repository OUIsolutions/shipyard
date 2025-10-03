# Shipyard
![VibeScript Logo](https://img.shields.io/badge/VibeScript-0.1.0-blue?style=for-the-badge&logo=lua)
[![GitHub Release](https://img.shields.io/badge/GitHub-Release-blue?style=for-the-badge)](https://github.com/OUIsolutions/shipyard/releases)
[![License](https://img.shields.io/badge/License-Unlicense-green.svg?style=for-the-badge)](https://github.com/OUIsolutions/shipyard/blob/main/LICENSE)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)
![Platforms](https://img.shields.io/badge/Platforms-VibeScript-lightgrey?style=for-the-badge)

---

### Overview

Shipyard is a powerful GitHub release management tool for VibeScript that allows you to automate creating and managing GitHub releases directly from the command line. It provides a template-based system for version management and asset handling:

1. **Install VibeScript runtime**
2. **Configure Shipyard with your release settings**
3. **Create releases from anywhere**

This tool is designed for developers who want to:
- Automate GitHub release creation from scripts and CI/CD pipelines
- Manage version numbers with template-based configuration
- Upload and manage release assets efficiently
- Create and update Git tags automatically

### Key Features

- **Automated Release Creation** - Streamline your GitHub release workflow.
- **Template-Based Versioning** - Use customizable replacers for version management.
- **Dynamic Replacer Modification** - Update version numbers without manual JSON editing.
- **Asset Management** - Automatically upload and manage release assets.
- **Smart Tag Handling** - Create new tags or update existing ones.
- **JSON Configuration** - Simple, declarative configuration format.

## Installation

### Step 1: Install VibeScript

Choose the appropriate installation method for your operating system:

#### Option A: Pre-compiled Binary (Linux only)
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/vibescript.out -o vibescript.out && chmod +x vibescript.out && sudo mv vibescript.out /usr/local/bin/vibescript
```

#### Option B: Compile from Source (Linux and macOS)
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/amalgamation.c -o vibescript.c && gcc vibescript.c -o vibescript.out && sudo mv vibescript.out /usr/local/bin/vibescript
```

### Step 2: Install Shipyard
```bash
vibescript add_script --file https://github.com/OUIsolutions/shipyard/releases/download/0.1.0/shipyard.lua shipyard
```

## Usage

Shipyard uses a JSON-based configuration system to manage your GitHub releases. First, set up a release configuration file, then create releases using that configuration.

### Setting Up Configuration

Create a `release.json` file in your project root with the following structure:

```json
{
   "replacers": {
       "BIG_VERSION": "0",
       "SMALL_VERSION": "1",
       "PATCH_VERSION": "0"
   },
   "release": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
   "tag": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
   "description": "description of the release",
   "assets": ["path/to/asset1", "path/to/asset2"]
}
```

### Command Line Options

#### Create Release Command
- `<config-file>`: Path to the JSON configuration file (e.g., `release.json`)

#### Modify Replacer Command
- `--name` or `-n`: The replacer key to modify (required)
- `--value` or `-v`: The new value for the replacer (required)
- `--file` or `-f`: Path to configuration file (optional, defaults to `release.json`)

#### Increment/Decrement Replacer Commands
- `--name` or `-n`: The replacer key to increment/decrement (required)
- `--file` or `-f`: Path to configuration file (optional, defaults to `release.json`)

### Example Usage

#### Create a release
```bash
shipyard release.json
```

#### Modify a replacer value
```bash
shipyard modify_replacer --name BIG_VERSION --value 1
```

#### Increment the patch version
```bash
shipyard increment_replacer --name PATCH_VERSION
```

#### Decrement a build number
```bash
shipyard decrement_replacer --name BUILD_NUMBER --file devops/release.json
```

#### Using short flags
```bash
shipyard modify_replacer -n PATCH_VERSION -v 5 -f release.json
```

### Configuration File Format

The configuration file uses JSON with these fields:

- **replacers** (required): Key-value pairs for template substitution
- **release** (required): Release name template using `{KEY}` syntax
- **tag** (required): Git tag template using `{KEY}` syntax
- **description** (required): Release description (supports template variables)
- **assets** (optional): Array of file paths to upload


---

## 📄 License

This project is released into the public domain under the [Unlicense](LICENSE).