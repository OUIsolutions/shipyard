# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shipyard is a GitHub release management tool written in Lua for the VibeScript ecosystem. It automates creating GitHub releases with template-based version management, asset uploads, and tag handling.

## Architecture

The codebase follows a three-layer architecture in a single file (`shipyard.lua`):

1. **PRIVATE_SHIPYARD_API**: Internal helper functions (file operations, command execution, template processing, validation)
2. **SHIPYARD_API**: Public API exposed for programmatic use - all functions return `(success, error, [data])` pattern
3. **SHIPYARD_CLI**: Command-line interface layer that catches API errors and presents user-friendly messages

### Key Design Patterns

- **Error Handling**: API functions return `(success, error, data)` tuples. CLI layer catches errors and displays them with emoji prefixes (❌, ✅, ℹ️)
- **Template System**: Uses `{VARIABLE_NAME}` syntax in strings, replaced via `PRIVATE_SHIPYARD_API.apply_replacers()`
- **Command Execution**: Git and GitHub CLI commands wrapped in `PRIVATE_SHIPYARD_API.execute_command()`

## Development Commands

### Running Shipyard

```bash
# Create/update a release
vibescript shipyard.lua release.json

# Modify a replacer value
vibescript shipyard.lua modify_replacer --name BIG_VERSION --value 1 --file release.json

# Increment a numeric replacer
vibescript shipyard.lua increment_replacer --name PATCH_VERSION --file release.json

# Decrement a numeric replacer
vibescript shipyard.lua decrement_replacer --name PATCH_VERSION --file release.json
```

### Installing as VibeScript Command

```bash
vibescript add_script --file shipyard.lua shipyard
```

After installation, use `shipyard` instead of `vibescript shipyard.lua`.

### Testing a Release

The `devops/release.json` file contains the release configuration for Shipyard itself.

## Configuration Format

Release configuration files use JSON with these fields:

- **replacers** (required): Key-value pairs for template substitution
- **release** (required): Release name template using `{KEY}` syntax
- **tag** (required): Git tag template using `{KEY}` syntax
- **description** (required): Release description (supports template variables)
- **assets** (optional): Array of file paths to upload

## Dependencies

- **VibeScript**: Lua-based scripting environment (provides `json`, `dtw`, `argv` modules)
- **Git**: Version control operations
- **GitHub CLI (`gh`)**: Release and repository operations

## Important Notes

- All API functions validate inputs and return error messages instead of calling `os.exit()`
- CLI functions perform environment checks (git repo, gh auth, etc.) before operations
- The `is_main_script` guard at the end allows the file to be used as both a library and CLI tool
- Tag creation automatically pushes to remote repository
- Existing releases are deleted and recreated (not updated in-place)
- Assets are uploaded with `--clobber` to replace existing files
