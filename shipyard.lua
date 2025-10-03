-- ============================================
-- PRIVATE API - Internal Functions
-- ============================================
local PRIVATE_SHIPYARD_API = {}

PRIVATE_SHIPYARD_API.file_exists = function(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

PRIVATE_SHIPYARD_API.execute_command = function(cmd)
    local ok, _, code = os.execute(cmd)
    if not ok then
        return code or 1
    end
    return code or 0
end

PRIVATE_SHIPYARD_API.command_succeeded = function(result)
    if type(result) == "number" then
        return result == 0
    else
        return result
    end
end

PRIVATE_SHIPYARD_API.apply_replacers = function(template, replacers)
    if not template then
        error("Template is nil")
    end

    local result = template

    for key, value in pairs(replacers) do
        local pattern = "{" .. key .. "}"
        result = string.gsub(result, pattern, tostring(value))
    end

    -- Check if there are still unresolved variables
    local unresolved = string.match(result, "{([^}]+)}")
    if unresolved then
        error("Undefined variable in template: {" .. unresolved .. "}")
    end

    return result
end

PRIVATE_SHIPYARD_API.validate_config = function(config)
    if not config.replacers then
        error("'replacers' field is required in configuration file")
    end

    if not config.release then
        error("'release' field is required in configuration file")
    end

    if not config.tag then
        error("'tag' field is required in configuration file")
    end

    if not config.description then
        error("'description' field is required in configuration file")
    end
end

PRIVATE_SHIPYARD_API.keys_of_table = function(t)
    local keys = {}
    for k, _ in pairs(t) do
        table.insert(keys, k)
    end
    return keys
end

PRIVATE_SHIPYARD_API.tag_exists = function(tag)
    local result = PRIVATE_SHIPYARD_API.execute_command("git tag -l " .. tag .. " | grep -q '^" .. tag .. "$'")
    return result == 0
end

PRIVATE_SHIPYARD_API.release_exists = function(tag)
    local result = PRIVATE_SHIPYARD_API.execute_command("gh release view " .. tag .. " > /dev/null 2>&1")
    return result == 0
end

-- ============================================
-- PUBLIC API - Exposed Functions
-- ============================================
local SHIPYARD_API = {}

SHIPYARD_API.load_config = function(config_path)
    if not PRIVATE_SHIPYARD_API.file_exists(config_path) then
        error("Configuration file not found: " .. config_path)
    end

    local config = json.load_from_file(config_path)

    if not config then
        error("Failed to parse JSON file")
    end

    return config
end

SHIPYARD_API.save_config = function(config_path, config)
    local parsed = json.dumps_to_string(config)
    dtw.write_file(config_path, parsed)
end

SHIPYARD_API.modify_replacer = function(config_path, key, value)
    local config = SHIPYARD_API.load_config(config_path)

    if not config.replacers then
        error("'replacers' field not found in configuration file")
    end

    if config.replacers[key] == nil then
        local keys = PRIVATE_SHIPYARD_API.keys_of_table(config.replacers)
        error("Replacer key '" .. key .. "' not found in configuration file. Available keys: " .. table.concat(keys, ", "))
    end

    local old_value = config.replacers[key]
    config.replacers[key] = value

    SHIPYARD_API.save_config(config_path, config)

    return {key = key, old_value = old_value, new_value = value}
end

SHIPYARD_API.increment_replacer = function(config_path, key)
    local config = SHIPYARD_API.load_config(config_path)

    if not config.replacers then
        error("'replacers' field not found in configuration file")
    end

    if config.replacers[key] == nil then
        local keys = PRIVATE_SHIPYARD_API.keys_of_table(config.replacers)
        error("Replacer key '" .. key .. "' not found in configuration file. Available keys: " .. table.concat(keys, ", "))
    end

    local old_value = config.replacers[key]
    local num_value = tonumber(old_value)

    if not num_value then
        error("Replacer value '" .. tostring(old_value) .. "' is not a valid number. The increment_replacer command only works with numeric values")
    end

    local new_value = num_value + 1
    config.replacers[key] = tostring(new_value)

    SHIPYARD_API.save_config(config_path, config)

    return {key = key, old_value = old_value, new_value = tostring(new_value)}
end

SHIPYARD_API.decrement_replacer = function(config_path, key)
    local config = SHIPYARD_API.load_config(config_path)

    if not config.replacers then
        error("'replacers' field not found in configuration file")
    end

    if config.replacers[key] == nil then
        local keys = PRIVATE_SHIPYARD_API.keys_of_table(config.replacers)
        error("Replacer key '" .. key .. "' not found in configuration file. Available keys: " .. table.concat(keys, ", "))
    end

    local old_value = config.replacers[key]
    local num_value = tonumber(old_value)

    if not num_value then
        error("Replacer value '" .. tostring(old_value) .. "' is not a valid number. The decrement_replacer command only works with numeric values")
    end

    local new_value = num_value - 1
    config.replacers[key] = tostring(new_value)

    SHIPYARD_API.save_config(config_path, config)

    return {key = key, old_value = old_value, new_value = tostring(new_value)}
end

SHIPYARD_API.create_tag = function(tag, description)
    local cmd = string.format("git tag -a %s -m '%s'", tag, description)
    local result = PRIVATE_SHIPYARD_API.execute_command(cmd)

    if result ~= 0 then
        error("Failed to create tag")
    end

    -- Push tag to remote repository
    result = PRIVATE_SHIPYARD_API.execute_command("git push origin " .. tag)

    if result ~= 0 then
        error("Failed to push tag to repository")
    end
end

SHIPYARD_API.ensure_tag_pushed = function(tag)
    local result = os.execute("git ls-remote --tags origin " .. tag .. " | grep -q " .. tag)

    if result ~= 0 then
        local push_result = PRIVATE_SHIPYARD_API.execute_command("git push origin " .. tag)
        if push_result ~= 0 then
            error("Failed to push existing tag to remote repository")
        end
    end
end

SHIPYARD_API.create_release = function(tag, release_name, description)
    local escaped_desc = string.gsub(description, '"', '\\"')

    local cmd = string.format('gh release create "%s" --title "%s" --notes "%s"',
        tag, release_name, escaped_desc)

    local result = PRIVATE_SHIPYARD_API.execute_command(cmd)

    if result ~= 0 then
        error("Failed to create release")
    end
end

SHIPYARD_API.update_release = function(tag, release_name, description)
    local delete_result = PRIVATE_SHIPYARD_API.execute_command(string.format('gh release delete "%s" -y', tag))

    if delete_result ~= 0 then
        error("Failed to delete existing release")
    end

    SHIPYARD_API.create_release(tag, release_name, description)
end

SHIPYARD_API.upload_assets = function(tag, assets)
    if not assets or #assets == 0 then
        return
    end

    for _, asset_path in ipairs(assets) do
        if not PRIVATE_SHIPYARD_API.file_exists(asset_path) then
            error("Asset not found: " .. asset_path)
        end

        local cmd = string.format('gh release upload "%s" "%s" --clobber', tag, asset_path)
        local result = PRIVATE_SHIPYARD_API.execute_command(cmd)

        if result ~= 0 then
            error("Failed to upload asset: " .. asset_path)
        end
    end
end

SHIPYARD_API.generate_release = function(config)
    -- Validate configuration
    PRIVATE_SHIPYARD_API.validate_config(config)

    -- Apply replacers to templates
    local release_name = PRIVATE_SHIPYARD_API.apply_replacers(config.release, config.replacers)
    local tag = PRIVATE_SHIPYARD_API.apply_replacers(config.tag, config.replacers)
    local description = PRIVATE_SHIPYARD_API.apply_replacers(config.description, config.replacers)

    -- Check and create tag if necessary
    if not PRIVATE_SHIPYARD_API.tag_exists(tag) then
        SHIPYARD_API.create_tag(tag, description)
    else
        SHIPYARD_API.ensure_tag_pushed(tag)
    end

    -- Create or update release
    if PRIVATE_SHIPYARD_API.release_exists(tag) then
        SHIPYARD_API.update_release(tag, release_name, description)
    else
        SHIPYARD_API.create_release(tag, release_name, description)
    end

    -- Upload assets
    if config.assets then
        SHIPYARD_API.upload_assets(tag, config.assets)
    end
end

SHIPYARD_API.generate_release_from_json = function(json_file_path)
    local config = SHIPYARD_API.load_config(json_file_path)
    return SHIPYARD_API.generate_release(config)
end

-- ============================================
-- CLI Layer - User Interface Functions
-- ============================================
local SHIPYARD_CLI = {}

SHIPYARD_CLI.print_error = function(message)
    print("❌ ERROR: " .. message)
end

SHIPYARD_CLI.print_success = function(message)
    print("✅ " .. message)
end

SHIPYARD_CLI.print_info = function(message)
    print("ℹ️  " .. message)
end

SHIPYARD_CLI.check_gh_cli = function()
    local handle = io.popen("gh --version 2>&1")
    local _ = handle:read("*a")
    local success, _, code = handle:close()

    if not success or code ~= 0 then
        SHIPYARD_CLI.print_error("GitHub CLI (gh) is not installed!")
        SHIPYARD_CLI.print_error("Please install GitHub CLI: https://cli.github.com/")
        os.exit(1)
    end
end

SHIPYARD_CLI.check_gh_auth = function()
    local handle = io.popen("gh auth status > /dev/null 2>&1")
    local _ = handle:read("*a")
    local success, _, code = handle:close()

    if not success or code ~= 0 then
        SHIPYARD_CLI.print_error("GitHub CLI is not authenticated!")
        SHIPYARD_CLI.print_error("Please run: gh auth login")
        os.exit(1)
    end
end

SHIPYARD_CLI.check_git_repository = function()
    local result = PRIVATE_SHIPYARD_API.execute_command("git rev-parse --git-dir > /dev/null 2>&1")

    if not PRIVATE_SHIPYARD_API.command_succeeded(result) then
        SHIPYARD_CLI.print_error("This directory is not a Git repository!")
        print("Please run:")
        print("  git init")
        print("  git add .")
        print("  git commit -m 'Initial commit'")
        os.exit(1)
    end
end

SHIPYARD_CLI.check_git_commits = function()
    local result = PRIVATE_SHIPYARD_API.execute_command("git rev-parse HEAD > /dev/null 2>&1")

    if not PRIVATE_SHIPYARD_API.command_succeeded(result) then
        SHIPYARD_CLI.print_error("The repository has no commits!")
        print("Please make the first commit:")
        print("  git add .")
        print("  git commit -m 'Initial commit'")
        os.exit(1)
    end
end

SHIPYARD_CLI.check_git_remote = function()
    local result = PRIVATE_SHIPYARD_API.execute_command("git remote get-url origin > /dev/null 2>&1")

    if not PRIVATE_SHIPYARD_API.command_succeeded(result) then
        SHIPYARD_CLI.print_error("The repository doesn't have 'origin' remote configured!")
        print("Please configure the remote:")
        print("  git remote add origin https://github.com/username/repository.git")
        print("  git push -u origin main")
        os.exit(1)
    end
end

SHIPYARD_CLI.show_help = function()
    print([[
🚢 Shipyard - GitHub Release Manager

USAGE:
    shipyard <configuration-file.json>
    shipyard modify_replacer --name <KEY> --value <VALUE> [--file <config-file>]
    shipyard increment_replacer --name <KEY> [--file <config-file>]
    shipyard decrement_replacer --name <KEY> [--file <config-file>]
    shipyard --help

COMMANDS:
    <configuration-file.json>    Create/update a GitHub release
    modify_replacer              Modify a replacer value in configuration file
    increment_replacer           Increment a numeric replacer value by 1
    decrement_replacer           Decrement a numeric replacer value by 1

MODIFY_REPLACER OPTIONS:
    --name <KEY>                 The replacer key to modify (required)
    --value <VALUE>              The new value for the replacer (required)
    --file <config-file>         Path to configuration file (default: release.json)

INCREMENT_REPLACER OPTIONS:
    --name <KEY>                 The replacer key to increment (required)
    --file <config-file>         Path to configuration file (default: release.json)

DECREMENT_REPLACER OPTIONS:
    --name <KEY>                 The replacer key to decrement (required)
    --file <config-file>         Path to configuration file (default: release.json)

GENERAL OPTIONS:
    --help, -h                   Show this help message

CONFIGURATION EXAMPLE (release.json):
    {
        "replacers": {
            "BIG_VERSION": "1",
            "SMALL_VERSION": "0",
            "PATCH_VERSION": "0"
        },
        "release": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
        "tag": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
        "description": "Release description",
        "assets": ["path/to/asset1", "path/to/asset2"]
    }

REQUIRED FIELDS:
    - replacers: Key-value pairs for substitution
    - release: Release name template
    - tag: Git tag template
    - description: Release description

OPTIONAL FIELDS:
    - assets: Array of file paths

PREREQUISITES:
    - GitHub CLI (gh) installed and authenticated
    - Git repository initialized
    - Write access to repository

EXAMPLES:
    shipyard release.json
    shipyard modify_replacer --name BIG_VERSION --value 1
    shipyard modify_replacer --name PATCH_VERSION --value 5 --file devops/release.json
    shipyard increment_replacer --name PATCH_VERSION
    shipyard increment_replacer --name BIG_VERSION --file devops/release.json
    shipyard decrement_replacer --name PATCH_VERSION
    shipyard decrement_replacer --name BIG_VERSION --file devops/release.json
]])
end

SHIPYARD_CLI.get_config_file_or_default = function()
    local config_file = argv.get_flag_arg_by_index({"file"}, 1)
    return config_file or "release.json"
end

SHIPYARD_CLI.validate_required_arg = function(arg, arg_name, usage_message)
    if not arg then
        SHIPYARD_CLI.print_error("Missing required argument: --" .. arg_name)
        print("")
        print("Use: " .. usage_message)
        print("Or: shipyard --help for more information")
        os.exit(1)
    end
end

SHIPYARD_CLI.handle_modify_replacer = function()
    local name = argv.get_flag_arg_by_index({"name"}, 1)
    local value = argv.get_flag_arg_by_index({"value"}, 1)
    local config_file = SHIPYARD_CLI.get_config_file_or_default()

    SHIPYARD_CLI.validate_required_arg(name, "name", "shipyard modify_replacer --name <KEY> --value <VALUE> [--file <config-file>]")
    SHIPYARD_CLI.validate_required_arg(value, "value", "shipyard modify_replacer --name <KEY> --value <VALUE> [--file <config-file>]")

    local success, result = pcall(SHIPYARD_API.modify_replacer, config_file, name, value)
    if not success then
        SHIPYARD_CLI.print_error(result)
        os.exit(1)
    end

    SHIPYARD_CLI.print_success("Replacer updated successfully!")
    SHIPYARD_CLI.print_info("Key: " .. result.key)
    SHIPYARD_CLI.print_info("Old value: " .. tostring(result.old_value))
    SHIPYARD_CLI.print_info("New value: " .. tostring(result.new_value))
    os.exit(0)
end

SHIPYARD_CLI.handle_increment_replacer = function()
    local name = argv.get_flag_arg_by_index({"name"}, 1)
    local config_file = SHIPYARD_CLI.get_config_file_or_default()

    SHIPYARD_CLI.validate_required_arg(name, "name", "shipyard increment_replacer --name <KEY> [--file <config-file>]")

    local success, result = pcall(SHIPYARD_API.increment_replacer, config_file, name)
    if not success then
        SHIPYARD_CLI.print_error(result)
        os.exit(1)
    end

    SHIPYARD_CLI.print_success("Replacer incremented successfully!")
    SHIPYARD_CLI.print_info("Key: " .. result.key)
    SHIPYARD_CLI.print_info("Old value: " .. tostring(result.old_value))
    SHIPYARD_CLI.print_info("New value: " .. tostring(result.new_value))
    os.exit(0)
end

SHIPYARD_CLI.handle_decrement_replacer = function()
    local name = argv.get_flag_arg_by_index({"name"}, 1)
    local config_file = SHIPYARD_CLI.get_config_file_or_default()

    SHIPYARD_CLI.validate_required_arg(name, "name", "shipyard decrement_replacer --name <KEY> [--file <config-file>]")

    local success, result = pcall(SHIPYARD_API.decrement_replacer, config_file, name)
    if not success then
        SHIPYARD_CLI.print_error(result)
        os.exit(1)
    end

    SHIPYARD_CLI.print_success("Replacer decremented successfully!")
    SHIPYARD_CLI.print_info("Key: " .. result.key)
    SHIPYARD_CLI.print_info("Old value: " .. tostring(result.old_value))
    SHIPYARD_CLI.print_info("New value: " .. tostring(result.new_value))
    os.exit(0)
end

SHIPYARD_CLI.handle_process_release = function(config_path)
    local success, err = pcall(SHIPYARD_API.generate_release_from_json, config_path)
    if not success then
        SHIPYARD_CLI.print_error(err)
        os.exit(1)
    end

    SHIPYARD_CLI.print_success("Release published successfully! 🚀")
    os.exit(0)
end

function SHIPYARD_CLI.main()
    -- Check if help was requested
    if argv.flags_exist({ "h", "help" }) then
        SHIPYARD_CLI.show_help()
        os.exit(0)
    end

    -- Get first argument (could be a command or config file)
    local first_arg = argv.get_next_unused()

    -- Route to appropriate command handler
    local commands = {
        modify_replacer = SHIPYARD_CLI.handle_modify_replacer,
        increment_replacer = SHIPYARD_CLI.handle_increment_replacer,
        decrement_replacer = SHIPYARD_CLI.handle_decrement_replacer
    }

    local command_handler = commands[first_arg]
    if command_handler then
        command_handler()
        return
    end

    -- Otherwise, treat first_arg as configuration file
    if not first_arg then
        SHIPYARD_CLI.print_error("No configuration file specified")
        print("")
        print("Use: shipyard <configuration-file.json>")
        print("Or: shipyard --help for more information")
        os.exit(1)
    end

    SHIPYARD_CLI.check_gh_cli()
    SHIPYARD_CLI.check_gh_auth()
    SHIPYARD_CLI.check_git_repository()
    SHIPYARD_CLI.check_git_commits()
    SHIPYARD_CLI.check_git_remote()

    SHIPYARD_CLI.handle_process_release(first_arg)
end
if is_main_script then 
SHIPYARD_CLI.main()
end
if not is_main_script then
    return SHIPYARD_API
end