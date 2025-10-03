-- ============================================
-- Utils
-- ============================================

local function print_error(message)
    print("❌ ERROR: " .. message)
end

local function print_success(message)
    print("✅ " .. message)
end

local function print_info(message)
    print("ℹ️  " .. message)
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

local function execute_command(cmd)
    local ok, _, code = os.execute(cmd)
    if not ok then
        return code or 1
    end
    return code or 0
end

-- ============================================
-- Prerequisites Check
-- ============================================

local function check_gh_cli()

    local handle = io.popen("gh --version 2>&1")
    local output = handle:read("*a")
    local success, _, code = handle:close()

    if not success or code ~= 0 then
        print_error("GitHub CLI (gh) is not installed!")
        print_error("Please install GitHub CLI: https://cli.github.com/")
        os.exit(1)
    end

end


local function check_gh_auth()
    local handle = io.popen("gh auth status > /dev/null 2>&1")
    local output = handle:read("*a")
    local success, _, code = handle:close()

    if not success or code ~= 0 then
        print_error("GitHub CLI is not authenticated!")
        print_error("Please run: gh auth login")
        os.exit(1)
    end
end


local function check_git_repository()
    local result = execute_command("git rev-parse --git-dir > /dev/null 2>&1")
    
    local success = false
    if type(result) == "number" then
        success = (result == 0)
    else
        success = result
    end
    
    if not success then
        print_error("This directory is not a Git repository!")
        print("Please run:")
        print("  git init")
        print("  git add .")
        print("  git commit -m 'Initial commit'")
        os.exit(1)
    end
end

local function check_git_commits()
    local result = execute_command("git rev-parse HEAD > /dev/null 2>&1")
    
    local success = false
    if type(result) == "number" then
        success = (result == 0)
    else
        success = result
    end
    
    if not success then
        print_error("The repository has no commits!")
        print("Please make the first commit:")
        print("  git add .")
        print("  git commit -m 'Initial commit'")
        os.exit(1)
    end
end

local function check_git_remote()
    local result = execute_command("git remote get-url origin > /dev/null 2>&1")
    
    local success = false
    if type(result) == "number" then
        success = (result == 0)
    else
        success = result
    end
    
    if not success then
        print_error("The repository doesn't have 'origin' remote configured!")
        print("Please configure the remote:")
        print("  git remote add origin https://github.com/username/repository.git")
        print("  git push -u origin main")
        os.exit(1)
    end
end


-- ============================================
-- Template System
-- ============================================

local function apply_replacers(template, replacers)
    if not template then
        return nil
    end
    
    local result = template
    
    for key, value in pairs(replacers) do
        local pattern = "{" .. key .. "}"
        result = string.gsub(result, pattern, tostring(value))
    end
    
    -- Check if there are still unresolved variables
    local unresolved = string.match(result, "{([^}]+)}")
    if unresolved then
        print_error("Undefined variable in template: {" .. unresolved .. "}")
        return nil
    end
    
    return result
end

-- ============================================
-- Configuration Validation
-- ============================================

local function validate_config(config)
    if not config.replacers then
        print_error("'replacers' field is required in configuration file")
        return false
    end
    
    if not config.release then
        print_error("'release' field is required in configuration file")
        return false
    end
    
    if not config.tag then
        print_error("'tag' field is required in configuration file")
        return false
    end
    
    if not config.description then
        print_error("'description' field is required in configuration file")
        return false
    end
    
    return true
end

-- ============================================
-- Tag Management
-- ============================================

local function ensure_tag_pushed(tag)

    -- Check if tag exists on remote
    local result = os.execute("git ls-remote --tags origin " .. tag .. " | grep -q " .. tag)

    if result ~= 0 then
        -- If it doesn't exist on remote, push it
        local push_result = execute_command("git push origin " .. tag)
        if push_result ~= 0 then
            print_error("Failed to push existing tag to remote repository")
            return false
        end
    end

    return true
end


local function tag_exists(tag)
    local result = execute_command("git tag -l " .. tag .. " | grep -q '^" .. tag .. "$'")
    return result == 0
end

local function create_tag(tag, description)


    local cmd = string.format("git tag -a %s -m '%s'", tag, description)
    local result = execute_command(cmd)
    
    if result ~= 0 then
        print_error("Failed to create tag")
        return false
    end
    
    -- Push tag to remote repository
    result = execute_command("git push origin " .. tag)
    
    if result ~= 0 then
        print_error("Failed to push tag to repository")
        return false
    end
    
    return true
end


-- ============================================
-- Release Management
-- ============================================

local function release_exists(tag)
    local result = execute_command("gh release view " .. tag .. " > /dev/null 2>&1")
    return result == 0
end

local function create_release(tag, release_name, description)
    
    -- Escape quotes in description
    local escaped_desc = string.gsub(description, '"', '\\"')
    
    local cmd = string.format('gh release create "%s" --title "%s" --notes "%s"',
        tag, release_name, escaped_desc)
    
    local result = execute_command(cmd)
    
    if result ~= 0 then
        print_error("Failed to create release")
        return false
    end
    
    return true
end

local function update_release(tag, release_name, description)
    
    -- For older versions of gh CLI that don't support 'gh release edit',
    -- we need to delete and recreate the release
    print("Deleting existing release to update...")
    local delete_result = execute_command(string.format('gh release delete "%s" -y', tag))
    
    if delete_result ~= 0 then
        print_error("Failed to delete existing release")
        return false
    end
    
    -- Recreate the release with updated information
    return create_release(tag, release_name, description)
end

-- ============================================
-- Asset Management
-- ============================================

local function upload_assets(tag, assets)
    if not assets or #assets == 0 then
        print_info("No assets to upload")
        return true
    end
    
    for i, asset_path in ipairs(assets) do
        if not file_exists(asset_path) then
            print_error("Asset not found: " .. asset_path)
            return false
        end
        
        -- The gh release upload command automatically replaces existing assets
        local cmd = string.format('gh release upload "%s" "%s" --clobber', tag, asset_path)
        local result = execute_command(cmd)
        
        if result ~= 0 then
            print_error("Failed to upload asset: " .. asset_path)
            return false
        end
        
    end
    
    return true
end

-- ============================================
-- Main Function
-- ============================================

local function process_release(config_path)
    -- Check if file exists
    if not file_exists(config_path) then
        print_error("Configuration file not found: " .. config_path)
        return false
    end
    
    -- Read and parse JSON file
    local config = json.load_from_file(config_path)
    
    if not config then
        print_error("Failed to parse JSON file")
        return false
    end
    
    -- Validate configuration
    if not validate_config(config) then
        return false
    end
    
    -- Apply replacers to templates
    local release_name = apply_replacers(config.release, config.replacers)
    local tag = apply_replacers(config.tag, config.replacers)
    local description = apply_replacers(config.description, config.replacers)
    
    if not release_name or not tag or not description then
        return false
    end
    
    -- Check and create tag if necessary
    if not tag_exists(tag) then
        if not create_tag(tag, description) then
            return false
        end
    else
        ensure_tag_pushed(tag)
    end
    
    -- Create or update release
    if release_exists(tag) then
        if not update_release(tag, release_name, description) then
            return false
        end
    else
        if not create_release(tag, release_name, description) then
            return false
        end
    end
    
    -- Upload assets
    if config.assets then
        if not upload_assets(tag, config.assets) then
            return false
        end
    end
    
    print_success("Release published successfully! 🚀")
    return true
end

-- ============================================
-- CLI Interface
-- ============================================

local function show_help()
    print([[
🚢 Shipyard - GitHub Release Manager

USAGE:
    shipyard <configuration-file.json>
    shipyard --help

ARGUMENTS:
    <configuration-file.json>    Path to JSON configuration file

OPTIONS:
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

EXAMPLE:
    shipyard release.json
]])
end

-- ============================================
-- Entry Point
-- ============================================

local function main()
    -- Check if help was requested
    local help_arg = argv.flags_exist({ "h", "help" })
    if help_arg then
        show_help()
        os.exit(0)
    end
    
    -- Get configuration file
    local config_file = argv.get_next_unused()
    if not config_file then
        print_error("No configuration file specified")
        print("")
        print("Use: shipyard <configuration-file.json>")
        print("Or: shipyard --help for more information")
        os.exit(1)
    end

    
    check_gh_cli()
    check_gh_auth()

    check_git_repository()
    check_git_commits()
    check_git_remote()

    local success = process_release(config_file)
    
    if not success then
        os.exit(1)
    end

    os.exit(0)
end

main()