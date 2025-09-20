<div align="center">

# 🚢 Shipyard

**GitHub Release Management Tool for VibeScript**

[![GitHub release](https://img.shields.io/github/release/OUIsolutions/shipyard.svg)](https://github.com/OUIsolutions/shipyard/releases)
[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](https://unlicense.org/)
[![VibeScript](https://img.shields.io/badge/powered%20by-VibeScript-orange.svg)](https://github.com/OUIsolutions/VibeScript)

---

</div>

## 📋 Overview

Shipyard is a powerful GitHub release management tool built for the VibeScript ecosystem. It automates the process of creating and managing GitHub releases with customizable version templating, asset management, and tag handling.

## ✨ Key Features

- **🔄 Automated Release Creation**: Streamline your GitHub release workflow
- **📝 Template-Based Versioning**: Use customizable replacers for version management
- **📦 Asset Management**: Automatically upload and manage release assets
- **🏷️ Smart Tag Handling**: Create new tags or update existing ones
- **⚙️ JSON Configuration**: Simple, declarative configuration format
- **🔧 VibeScript Integration**: Built specifically for the VibeScript ecosystem

## 🚀 Installation

### Prerequisites

Shipyard requires VibeScript to be installed on your system. Follow the installation guide below:

#### For Linux Users (Recommended)

**Option A: Pre-compiled Binary**
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/vibescript.out -o vibescript.out
chmod +x vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

**Option B: Compile from Source**
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/amalgamation.c -o vibescript.c
gcc vibescript.c -o vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

#### For macOS Users

```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/amalgamation.c -o vibescript.c
gcc vibescript.c -o vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

> **Note:** Make sure you have GCC installed. You can install it via Xcode Command Line Tools: `xcode-select --install`

### Installing Shipyard

1. **Clone the Repository**
```bash
git clone https://github.com/OUIsolutions/shipyard.git
cd shipyard
```

2. **Add to VibeScript Path**
```bash
vibescript add_script --file shipyard.lua shipyard
```

## 📖 Usage

### Configuration

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

### Creating a Release

Run the following command in your project directory:

```bash
shipyard release.json
```

### Configuration Options

| Field | Description | Required |
|-------|-------------|----------|
| `replacers` | Key-value pairs for template replacement | ✅ |
| `release` | Release name template using replacer variables | ✅ |
| `tag` | Git tag template using replacer variables | ✅ |
| `description` | Release description/changelog | ✅ |
| `assets` | Array of file paths to upload as release assets | ❌ |

### Behavior Notes

- **Tag Management**: If the specified tag doesn't exist, it will be created. If it exists, the release will be updated.
- **Asset Handling**: Existing assets with the same name will be replaced with new versions.
- **Template System**: Use `{VARIABLE_NAME}` syntax in release and tag fields to reference replacer values.

## 🔧 Examples

### Basic Release

```json
{
   "replacers": {
       "VERSION": "1.0.0"
   },
   "release": "v{VERSION}",
   "tag": "v{VERSION}",
   "description": "Initial release with core functionality"
}
```

### Advanced Release with Assets

```json
{
   "replacers": {
       "MAJOR": "2",
       "MINOR": "1",
       "PATCH": "3",
       "BUILD": "release"
   },
   "release": "Version {MAJOR}.{MINOR}.{PATCH}-{BUILD}",
   "tag": "{MAJOR}.{MINOR}.{PATCH}",
   "description": "Bug fixes and performance improvements",
   "assets": [
       "dist/shipyard-linux.tar.gz",
       "dist/shipyard-macos.tar.gz",
       "CHANGELOG.md"
   ]
}
```

## 📚 Documentation

For comprehensive documentation and advanced usage examples, visit:

- [VibeScript Documentation](https://github.com/OUIsolutions/VibeScript)
- [GitHub API Documentation](https://docs.github.com/en/rest/releases)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

## 📄 License

This project is released into the public domain under the [Unlicense](LICENSE).

---

