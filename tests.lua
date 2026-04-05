local lest = require("lest")

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
