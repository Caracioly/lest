local lest = {}

local state = {
    tests = {},
    prefixStack = {},
    config = {
        colors = true,
        unicode = nil,
        showStack = false
    }
}

local ANSI_RESET = "\27[0m"
local ANSI_RED = "\27[31m"
local ANSI_GREEN = "\27[32m"
local ANSI_YELLOW = "\27[33m"
local ANSI_GRAY = "\27[90m"

local function isWindows()
    return package.config:sub(1, 1) == "\\"
end

local function supportsUnicode()
    if state.config.unicode ~= nil then
        return state.config.unicode
    end

    if not isWindows() then
        return true
    end

    if os.getenv("WT_SESSION") or os.getenv("TERM") then
        return true
    end

    return false
end

local function withColor(text, color)
    if not state.config.colors then
        return text
    end
    return color .. text .. ANSI_RESET
end

local function stripErrorLocation(err)
    local message = tostring(err)
    local _, _, withoutPrefix = message:find("^.-:%d+:%s*(.*)$")
    if withoutPrefix and withoutPrefix ~= "" then
        return withoutPrefix
    end
    return message
end

local function deepEqual(left, right, visited)
    if left == right then
        return true
    end

    local leftType = type(left)
    local rightType = type(right)

    if leftType ~= rightType then
        return false
    end

    if leftType ~= "table" then
        return false
    end

    visited = visited or {}
    if visited[left] and visited[left] == right then
        return true
    end
    visited[left] = right

    for key, value in pairs(left) do
        if not deepEqual(value, right[key], visited) then
            return false
        end
    end

    for key in pairs(right) do
        if left[key] == nil then
            return false
        end
    end

    return true
end

local function formatValue(value)
    if type(value) == "string" then
        return string.format("%q", value)
    end
    return tostring(value)
end

local function currentPrefix()
    if #state.prefixStack == 0 then
        return ""
    end
    return table.concat(state.prefixStack, " ") .. " "
end

function lest.describe(name, fn)
    table.insert(state.prefixStack, name)
    local ok, err = pcall(fn)
    table.remove(state.prefixStack)

    if not ok then
        error(err, 0)
    end
end

function lest.it(name, fn)
    local suiteName = table.concat(state.prefixStack, " ")
    table.insert(state.tests, {
        suite = suiteName ~= "" and suiteName or "(root)",
        name = name,
        fullName = currentPrefix() .. name,
        fn = fn
    })
end

function lest.expect(actual)
    return {
        toBe = function(expected)
            if actual ~= expected then
                error(
                    string.format(
                        "Expected %s to be %s",
                        formatValue(actual),
                        formatValue(expected)
                    ),
                    0
                )
            end
        end,
        toEqual = function(expected)
            if not deepEqual(actual, expected) then
                error(
                    string.format(
                        "Expected %s to equal %s",
                        formatValue(actual),
                        formatValue(expected)
                    ),
                    0
                )
            end
        end
    }
end

function lest.configure(options)
    options = options or {}

    if options.colors ~= nil then
        state.config.colors = options.colors
    end

    if options.unicode ~= nil then
        state.config.unicode = options.unicode
    end

    if options.showStack ~= nil then
        state.config.showStack = options.showStack
    end
end

function lest.run()
    local passed = 0
    local failed = 0
    local startedAt = os.clock()
    local useUnicode = supportsUnicode()
    local passIcon = useUnicode and "✔" or "[OK]"
    local failIcon = useUnicode and "✖" or "[FAIL]"
    local suites = {}
    local suiteOrder = {}
    local failedTests = {}

    print(withColor("Running " .. tostring(#state.tests) .. " tests", ANSI_YELLOW))
    print("")

    for _, test in ipairs(state.tests) do
        local suiteStats = suites[test.suite]
        if not suiteStats then
            suiteStats = {
                total = 0,
                passed = 0,
                failed = 0
            }
            suites[test.suite] = suiteStats
            table.insert(suiteOrder, test.suite)
        end

        suiteStats.total = suiteStats.total + 1

        local ok, err = pcall(test.fn)
        if ok then
            passed = passed + 1
            suiteStats.passed = suiteStats.passed + 1
        else
            failed = failed + 1
            suiteStats.failed = suiteStats.failed + 1

            local message = state.config.showStack and tostring(err) or stripErrorLocation(err)
            table.insert(failedTests, {
                suite = test.suite,
                name = test.name,
                message = message
            })
        end
    end

    local suitePassed = 0
    local suiteFailed = 0
    for _, suiteName in ipairs(suiteOrder) do
        local suiteStats = suites[suiteName]
        local suiteOk = suiteStats.failed == 0

        if suiteOk then
            suitePassed = suitePassed + 1
            print(
                withColor(passIcon, ANSI_GREEN)
                    .. " "
                    .. suiteName
                    .. withColor(string.format(" (%d/%d)", suiteStats.passed, suiteStats.total), ANSI_GRAY)
            )
        else
            suiteFailed = suiteFailed + 1
            print(
                withColor(failIcon, ANSI_RED)
                    .. " "
                    .. suiteName
                    .. withColor(string.format(" (%d passed, %d failed)", suiteStats.passed, suiteStats.failed), ANSI_GRAY)
            )
        end
    end

    if failed > 0 then
        print("")
        print(withColor("Failed Tests", ANSI_RED))
        for _, failedTest in ipairs(failedTests) do
            print(withColor(failIcon, ANSI_RED) .. " " .. failedTest.suite .. " " .. failedTest.name)
            print("  " .. withColor(failedTest.message, ANSI_GRAY))
        end
    end

    print("")
    print(
        string.format(
            "Test Suites: %s failed, %s passed, %d total",
            withColor(tostring(suiteFailed), suiteFailed > 0 and ANSI_RED or ANSI_GRAY),
            withColor(tostring(suitePassed), suitePassed > 0 and ANSI_GREEN or ANSI_GRAY),
            #suiteOrder
        )
    )

    print(
        string.format(
            "Tests: %s failed, %s passed, %d total",
            withColor(tostring(failed), failed > 0 and ANSI_RED or ANSI_GRAY),
            withColor(tostring(passed), passed > 0 and ANSI_GREEN or ANSI_GRAY),
            #state.tests
        )
    )
    print("Time:  " .. withColor(string.format("%.3f s", os.clock() - startedAt), ANSI_YELLOW))

    if failed > 0 then
        return 1
    end

    return 0
end

return lest
