local function fileExists(path)
    local file = io.open(path, "r")
    if not file then
        return false
    end

    file:close()
    return true
end

local function requireLest()
    local ok, module = pcall(require, "lest")
    if ok then
        return module
    end

    local fallbackPaths = {
        "./libs/lest/lest.lua",
        "./libs/lest.lua",
        "./lib/lest/lest.lua",
        "./lib/lest.lua",
        "./lest.lua"
    }

    for _, path in ipairs(fallbackPaths) do
        if fileExists(path) then
            local chunk, loadError = loadfile(path)
            if not chunk then
                error("Failed to load 'lest' from " .. path .. ": " .. tostring(loadError), 0)
            end

            local loaded = chunk()
            package.loaded["lest"] = loaded
            return loaded
        end
    end

    error(
        "module 'lest' not found. Tried require('lest') and fallback paths: "
            .. table.concat(fallbackPaths, ", "),
        0
    )
end

local lest = requireLest()

local function listTestFiles(directory)
    local pathSeparator = package.config:sub(1, 1)
    local command

    if pathSeparator == "\\" then
        command = 'dir "' .. directory .. '" /b /s /a-d 2>nul'
    else
        command = 'find "' .. directory .. '" -type f 2>/dev/null'
    end

    local process = io.popen(command)
    if not process then
        return {}
    end

    local files = {}
    for filePath in process:lines() do
        if filePath:match("%.test%.lua$") then
            table.insert(files, filePath)
        end
    end

    process:close()
    table.sort(files)
    return files
end

local function loadTestsFrom(directory)
    local files = listTestFiles(directory)
    for _, filePath in ipairs(files) do
        dofile(filePath)
    end
end

local directories = { "__tests__", "tests" }

for _, directory in ipairs(directories) do
    loadTestsFrom(directory)
end

os.exit(lest.run())
