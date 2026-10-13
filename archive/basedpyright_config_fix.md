# BasedPyright Configuration Fix

## Issue #1: Incorrect Configuration Structure (RESOLVED)

The fleeting errors when opening Python files were caused by **incorrect configuration structure** in the LSP setup.

### Root Cause

In `common/nvim/lua/plugins/lsp.lua`, the `setup` section contained configuration tables instead of setup functions.

### Solution Applied

Moved the configuration to the correct location in the `servers` section.

---

## Issue #2: Wrong Command for LSP Server (RESOLVED)

### Error Message
```
Client basedpyright quit with exit code 1 and signal 0. 
Check log for errors: /home/mehays/.local/state/nvim/lsp.log
```

### Root Cause

The configuration was using `basedpyright` as the command, but this is the **CLI tool** for static analysis, not the **LSP server**.

When you install basedpyright via `uv tool install basedpyright`, you get two executables:

1. **`basedpyright`** - CLI tool for type checking and static analysis
   ```bash
   basedpyright --help
   # Shows: Usage: basedpyright [options] files...
   ```

2. **`basedpyright-langserver`** - LSP server for editor integration
   ```bash
   basedpyright-langserver --stdio
   # This is what Neovim needs to communicate via Language Server Protocol
   ```

### The Fix

Changed the command from:
```lua
cmd = { "basedpyright" }  -- ❌ Wrong: This is the CLI tool
```

To:
```lua
cmd = { "basedpyright-langserver", "--stdio" }  -- ✓ Correct: LSP server with stdio communication
```

### Why `--stdio` is Required

LSP servers communicate with editors using one of several methods:
- `--stdio`: Standard input/output (most common for Neovim)
- `--node-ipc`: Node.js IPC
- `--socket={number}`: TCP socket

Without specifying a communication method, basedpyright-langserver throws an error:
```
Error: Connection input stream is not set. Use arguments of createConnection or 
set command line parameters: '--node-ipc', '--stdio' or '--socket={number}'
```

## Final Working Configuration

### In `common/nvim/lua/plugins/lsp.lua`:

```lua
servers = {
  basedpyright = {
    cmd = { "basedpyright-langserver", "--stdio" },
    single_file_support = true,
    mason = false, -- Don't use Mason (managed by uv)
  },
},
setup = {
  -- No custom setup needed
}
```

## Final Working Configuration

### In `common/nvim/lua/plugins/lsp.lua`:

```lua
servers = {
  basedpyright = {
    cmd = { "basedpyright-langserver", "--stdio" },
    single_file_support = true,
    mason = false, -- Don't use Mason (managed by uv)
  },
},
setup = {
  -- No custom setup needed
}
```

## Verification

### BasedPyright Installation
```bash
$ which basedpyright-langserver
/home/mehays/.local/bin/basedpyright-langserver

$ basedpyright --version
basedpyright 1.39.4
based on pyright 1.1.409
```

### Neovim Configuration
```bash
$ nvim --headless '+qa'
Exit code: 0  ✓
```

## How It Works Now

1. When you open a Python file (`.py`), Neovim will:
   - Detect the Python filetype
   - Look for the `basedpyright` server in the configured servers
   - Start `basedpyright-langserver --stdio` from your PATH
   - Enable single file support for standalone Python files

2. Mason will skip basedpyright installation because `mason = false`

3. The LSP will provide:
   - Type checking
   - Code completion
   - Go to definition
   - Hover documentation
   - Error diagnostics
   - And all other basedpyright features

## Testing

To test the configuration:

1. **Restart Neovim completely** (important - kill all nvim instances)

2. Open a Python file:
   ```bash
   nvim test.py
   ```

3. Check LSP status:
   ```vim
   :LspInfo
   ```
   You should see `basedpyright` in the list of active clients with no errors

4. Test features:
   - Hover over a function: `K`
   - Go to definition: `gd`
   - See diagnostics in the sign column

## Summary

The exit code 1 error was caused by using the wrong executable. The fix:
- ❌ `basedpyright` (CLI tool)
- ✅ `basedpyright-langserver --stdio` (LSP server)

After restarting Neovim, basedpyright should now work without errors!
