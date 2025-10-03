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
- **� Dynamic Replacer Modification**: Update version numbers without manual JSON editing
- **�📦 Asset Management**: Automatically upload and manage release assets
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

### CLI Mode

#### Configuration

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

#### Creating a Release

Run the following command in your project directory:

```bash
shipyard release.json
```

#### Modifying Replacers

Update version numbers or other replacer values without manually editing the JSON file:

```bash
# Modify a replacer in the default release.json
shipyard modify_replacer --name BIG_VERSION --value 1

# Modify a replacer in a specific config file
shipyard modify_replacer --name PATCH_VERSION --value 5 --file devops/release.json
```

**Options:**
- `--name <KEY>`: The replacer key to modify (required)
- `--value <VALUE>`: The new value for the replacer (required)
- `--file <config-file>`: Path to configuration file (optional, defaults to `release.json`)

#### Showing Help

You can display usage instructions with:

```bash
shipyard --help
```

Or the shorthand:

```bash
shipyard -h
```

### API Mode

You can use Shipyard programmatically in your VibeScript projects.

#### Setup

First, install Shipyard as a global module:

```bash
vibescript add_script --file shipyard.lua shipyard
```

#### Loading the Module

In your VibeScript code, load Shipyard as a global module:

```lua
local shipyard = load_global_module("shipyard")
```

#### API Functions

All API functions raise errors on failure. Use `pcall` to handle errors gracefully.

##### `shipyard.generate_release_from_json(config_path)`

Creates a GitHub release based on a configuration file.

```lua
local success, err = pcall(shipyard.generate_release_from_json, "release.json")
if not success then
    print("Error: " .. err)
    return
end
print("Release created successfully!")
```

##### `shipyard.modify_replacer(config_path, key, value)`

Modifies a replacer value in the configuration file and returns a data table with `{key, old_value, new_value}`.

```lua
local success, data = pcall(shipyard.modify_replacer, "release.json", "PATCH_VERSION", "5")
if not success then
    print("Error: " .. data)
    return
end
print("Replacer updated successfully!")
print("Old value: " .. data.old_value .. ", New value: " .. data.new_value)
```

##### `shipyard.increment_replacer(config_path, key)`

Increments a numeric replacer value and returns a data table with `{key, old_value, new_value}`.

```lua
local success, data = pcall(shipyard.increment_replacer, "release.json", "PATCH_VERSION")
if not success then
    print("Error: " .. data)
    return
end
print("Replacer incremented successfully!")
print("Old value: " .. data.old_value .. ", New value: " .. data.new_value)
```

##### `shipyard.decrement_replacer(config_path, key)`

Decrements a numeric replacer value and returns a data table with `{key, old_value, new_value}`.

```lua
local success, data = pcall(shipyard.decrement_replacer, "release.json", "BUILD_NUMBER")
if not success then
    print("Error: " .. data)
    return
end
print("Replacer decremented successfully!")
print("Old value: " .. data.old_value .. ", New value: " .. data.new_value)
```

#### Example: Automated Release Script

```lua
local shipyard = load_global_module("shipyard")

-- Increment patch version
local success, result = pcall(shipyard.increment_replacer, "release.json", "PATCH_VERSION")
if not success then
    print("❌ Failed to increment version: " .. result)
    os.exit(1)
end

-- Create the release
success, result = pcall(shipyard.generate_release_from_json, "release.json")
if not success then
    print("❌ Failed to create release: " .. result)
    os.exit(1)
end

print("✅ Release created successfully!")
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

### Workflow Example: Releasing a Patch

```bash
# 1. Modify the patch version
shipyard modify_replacer --name PATCH_VERSION --value 1

# 2. Create and publish the release
shipyard release.json
```

### Workflow Example: Bumping Major Version

```bash
# Update major version and reset minor/patch
shipyard modify_replacer --name BIG_VERSION --value 2
shipyard modify_replacer --name SMALL_VERSION --value 0
shipyard modify_replacer --name PATCH_VERSION --value 0

# Create the release
shipyard release.json
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

