# Lest

Lest is a simple Lua testing library with a tiny API and a practical runner approach.

Core API:
- `describe`
- `it`
- `expect(...).toBe(...)`
- `expect(...).toEqual(...)`
- `expect(...).notToBe(...)`

## Philosophy

The recommended setup is simple:
- `lest.lua` as the library
- `tests.lua` as the runner
- test files in `__tests__` or `tests`

## Requirements

- Lua 5.1+

## Recommended Project Layout

```text
my-project/
  libs/
    lest.lua
  tests.lua
  __tests__/
    example.test.lua
```

You can also use `tests/` instead of `__tests__/`.

Only files ending with `.test.lua` are loaded by the runner.

## Installation

Preferred location for the library file:
- put `lest.lua` inside `libs/`

The default `tests.lua` runner already tries these paths automatically:
- `./libs/lest/lest.lua`
- `./libs/lest.lua`
- `./lib/lest/lest.lua`
- `./lib/lest.lua`
- `./lest.lua`

In most projects, no manual `package.path` setup is needed when using the runner.

If `lest.lua` is in `libs/`, add this before `require("lest")`:

```lua
package.path = package.path .. ";./libs/?.lua"
```

Then:

```lua
local lest = require("lest")
```

What `package.path` does (quickly):
- it tells Lua where `require()` should search for modules
- if Lua already finds your file, you do not need to change it

## Quick Start

Example test file (`__tests__/example.test.lua`):

```lua
local lest = require("lest")

lest.describe("example", function()
    lest.it("adds correctly", function()
        lest.expect(1 + 2).toBe(3)
    end)

    lest.it("compares table values", function()
        lest.expect({ a = 1, b = { c = 2 } }).toEqual({ a = 1, b = { c = 2 } })
    end)

    lest.it("supports negation", function()
        lest.expect(1).notToBe(2)
    end)
end)
```

Run from project root:

```bash
lua tests.lua
```

`tests.lua` is preferred in root because it is easier to run without changing directories.

## API

### `lest.describe(name, fn)`

Groups tests under a suite name. Nested `describe` blocks are supported.

### `lest.it(name, fn)`

Registers a test case.

### `lest.expect(actual)`

Returns an assertion object.

#### `toBe(expected)`

Strict equality (`==`).

#### `toEqual(expected)`

Deep equality for tables.

#### `notToBe(expected)`

Negated strict equality.

### `lest.configure(options)`

Runner output options:
- `colors` (`boolean`)
- `unicode` (`boolean | nil`)
- `showStack` (`boolean`)

### `lest.run()`

Executes registered tests and returns:
- `0` on success
- `1` when any test fails

## How The Runner Works

`tests.lua` loads tests from:
- `__tests__/`
- `tests/`

And executes only files matching:
- `*.test.lua`

Files are sorted before loading for stable/debug-friendly order.

## Tips

- Keep `tests.lua` in root for fast execution.
- Keep test names clear and behavior-focused.
- Prefer one behavior per `it(...)` block.

## Limitations (by design)

- no `beforeEach` / `afterEach`
- no mocks/spies
- no snapshots
- no async orchestration
- no watch mode

## License

See [LICENSE](https://github.com/Caracioly/lest/blob/main/LICENSE).

