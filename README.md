# cmp-pddl

> A comprehensive Neovim plugin for **PDDL** (Planning Domain Definition Language) — the standard input language for AI planners.

**Features:**
- 🔍 [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) autocompletion source
- 🤖 Integration with [solver.planning.domains](https://solver.planning.domains) for running planners
- 📊 Beautiful plan visualization with syntax highlighting
- 💾 Automatic plan file saving
- 🎨 Syntax highlighting and snippets

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [PDDL Solver Integration](#pddl-solver-integration)
- [Commands](#commands)
- [Autocompletion](#autocompletion)
- [Snippets](#snippet-support)
- [Development](#development)
- [License](#license)

---

## Features

### Autocompletion

| Category | What's completed |
|---|---|
| **Top-level keywords** | `define`, `domain`, `problem` |
| **Domain sections** | `:requirements` `:types` `:constants` `:predicates` `:functions` `:action` `:durative-action` `:derived` |
| **Problem sections** | `:domain` `:objects` `:init` `:goal` `:metric` |
| **Requirements** | All 20+ standard PDDL requirement flags |
| **Action sub-keys** | `:parameters` `:precondition` `:effect` `:duration` `:condition` |
| **Logical operators** | `and` `or` `not` `imply` `forall` `exists` `when` |
| **Temporal operators** | `at start` `at end` `over all` |
| **Numeric operators** | `increase` `decrease` `assign` `scale-up` `scale-down` |
| **Comparison** | `>` `<` `>=` `<=` `=` |
| **Metric** | `minimize` `maximize` `total-time` `total-cost` |
| **Buffer variables** | `?var` names extracted from the current buffer |
| **Buffer identifiers** | predicate / object names extracted from the current buffer |

Context-aware: completions change depending on whether you are inside a domain
or problem file, inside `:requirements`, `:action`, `:precondition`, `:effect`,
`:init`, `:goal`, etc.

### PDDL Solver Integration

- 🌐 Connect to planning-as-a-service servers (e.g., [solver.planning.domains](https://solver.planning.domains:5001))
- 🚀 Run any available planner (LAMA, Fast-Downward, dual-BFWS, etc.)
- 📊 Beautiful plan visualization with:
  - Color-coded syntax highlighting
  - Visual flow arrows (START → steps → GOAL)
  - Step numbering
  - Cost and metadata display
  - Planner output logs
- 💾 Automatic plan saving to `{domain}_{problem}_plan.txt`
- ⚡ Live progress bar with spinner during solving
- 🔄 Automatic polling for asynchronous solvers

---

## Requirements

- Neovim ≥ 0.9
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- `curl` (for solver integration)

---

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "ferisjuan/cmp-pddl",
  ft = "pddl",
  dependencies = { "hrsh7th/nvim-cmp" },
  config = function()
    require("cmp").setup.filetype("pddl", {
      sources = require("cmp").config.sources({
        { name = "pddl" },
        { name = "buffer" },
      }),
    })
  end,
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "ferisjuan/cmp-pddl",
  requires = { "hrsh7th/nvim-cmp" },
}
```

---

## Configuration

### Minimal setup (filetype-scoped)

```lua
local cmp = require("cmp")

-- Apply only to PDDL buffers
cmp.setup.filetype("pddl", {
  sources = cmp.config.sources({
    { name = "pddl",   priority = 1000 },
    { name = "buffer", priority = 500  },
  }),
})
```

### Global setup

```lua
require("cmp").setup({
  sources = require("cmp").config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip"  },
    { name = "pddl"     },   -- ← add this
    { name = "buffer"   },
  }),
})
```

---

## PDDL Solver Integration

### Quick Start

1. Open a PDDL domain file and problem file in Neovim
2. Run `:PddlSolve`
3. Select a server (or add a new one)
4. Select a planner
5. Watch the beautiful plan appear!

### Example Output

```
╔════════════════════════════════════════════════════════════════╗
║                        PDDL Plan Result                        ║
╚════════════════════════════════════════════════════════════════╝

  📋 Server   : https://solver.planning.domains:5001
  🤖 Planner  : dual-bfws-ffparser
  📊 Steps    : 44
  💰 Cost     : 44

  ✓  Plan found successfully!

  💾 Saved to : /path/to/blocks-domain_blocks-problem_plan.txt

  ┌─────────────────────────────────────────────────────────┐
  │  START
  │     ↓
  │   1. (UNSTACK C E)
  │     ↓
  │   2. (STACK C F)
  │     ↓
  │   3. (UNSTACK E J)
  │     ↓
  ...
  │     ↓
  │  🎯 GOAL
  └─────────────────────────────────────────────────────────┘
```

The output features:
- 🎨 **Color syntax highlighting** (step numbers in purple, actions in cyan, arrows in orange)
- 📊 **Metadata display** (server, planner, step count, cost)
- ➡️ **Visual flow** showing progression from START to GOAL
- 💾 **Auto-saved plans** to `{domain}_{problem}_plan.txt`
- 📝 **Planner logs** included at the bottom

---

## Commands

### `:PddlSolve`

Send your domain and problem to a PDDL planner and visualize the solution.

**Usage:**
1. Open both domain and problem files
2. Run `:PddlSolve`
3. Select server and planner
4. View the plan!

The command will:
- Automatically find domain/problem files in open buffers or current directory
- Validate the PDDL syntax before sending
- Show a live progress bar during solving
- Display the plan with beautiful formatting
- Save the plan to `{domain}_{problem}_plan.txt`

### `:PddlAddServer`

Add a new planning server.

**Default server:** `https://solver.planning.domains:5001`

**Usage:**
```vim
:PddlAddServer
```
Then enter the server URL and a friendly name.

### `:PddlServers`

List all saved planning servers.

**Usage:**
```vim
:PddlServers
```

### `:PddlParse`

Parse the current PDDL buffer and display its AST structure (useful for debugging).

**Usage:**
```vim
:PddlParse
```

### `:PddlReload`

Reload all cmp-pddl modules without restarting Neovim (useful during development).

**Usage:**
```vim
:PddlReload
```

---

## Autocompletion

The plugin provides context-aware autocompletion:

- **Domain files**: Suggests domain sections (`:action`, `:predicates`, etc.)
- **Problem files**: Suggests problem sections (`:init`, `:goal`, etc.)
- **Inside `:requirements`**: Shows all PDDL requirement flags
- **Inside actions**: Suggests `:parameters`, `:precondition`, `:effect`
- **Inside formulas**: Suggests logical operators (`and`, `or`, `not`, etc.)
- **Variables**: Extracts and suggests `?var` names from the buffer
- **Predicates/Objects**: Suggests identifiers defined in the buffer

---

## Snippet support

Snippets use LSP snippet syntax (`insertTextFormat = 2`). For them to expand
you need a snippet engine registered with nvim-cmp, such as
[LuaSnip](https://github.com/L3MON4D3/LuaSnip) or
[vim-vsnip](https://github.com/hrsh7th/vim-vsnip).

| Trigger | Expands to |
|---|---|
| `define-domain` | Full domain skeleton |
| `define-problem` | Full problem skeleton |
| `snippet-action` | `:action` block |
| `snippet-durative-action` | `:durative-action` block |
| `snippet-forall` | `(forall ...)` quantifier |
| `snippet-exists` | `(exists ...)` quantifier |
| `snippet-when` | `(when ...)` conditional effect |

---

## Syntax highlighting

The plugin ships a `syntax/pddl.vim` file that highlights:

- Keywords and section headers
- Requirement flags
- Variables (`?var`)
- Logical / temporal / numeric operators
- Comments (`;`)
- Numbers

Plan result buffers also feature custom highlighting:
- **Borders**: Muted blue-gray box drawing
- **Success/Error**: Green/red status indicators
- **Step numbers**: Purple, bold
- **Actions**: Cyan
- **Arrows**: Orange
- **Metadata**: Gray, italic

---

## Filetype settings

Automatically applied to every PDDL buffer:

- 2-space indentation
- `-` treated as part of a word (for identifiers like `:durative-action`)
- Comment string set to `; %s`
- Folding on parentheses with all folds open by default

---

## Development

### Project Structure

```
cmp-pddl/
├── lua/cmp_pddl/
│   ├── init.lua        # cmp source
│   ├── tokenizer.lua   # PDDL tokenizer
│   ├── syntax_tree.lua # S-expression parser
│   ├── parser.lua      # Domain/Problem extractor
│   ├── solver.lua      # HTTP client for planning-as-a-service
│   └── commands.lua    # :Pddl* commands
├── plugin/
│   └── cmp_pddl.lua    # Entry point, registers everything
├── syntax/
│   └── pddl.vim        # Syntax highlighting
└── ftplugin/
    └── pddl.lua        # Filetype settings
```

### Development Workflow

When developing the plugin:

1. Clone the repository:
   ```bash
   git clone https://github.com/ferisjuan/cmp-pddl.git ~/path/to/cmp-pddl
   cd ~/path/to/cmp-pddl
   ```

2. Make your changes in the source files

3. Sync to your Neovim installation:
   ```bash
   ./dev-sync.sh
   ```

4. In Neovim, reload the modules:
   ```vim
   :PddlReload
   ```

5. Test your changes immediately without restarting Neovim!

### Cache Management

The plugin automatically handles module caching:
- `plugin/cmp_pddl.lua` clears `vim.loader` cache on load
- `:PddlReload` command force-reloads all modules during development
- `SourcePost` autocmd ensures fresh loads after plugin updates

---

## API Documentation

### `solver.solve(server, planner, domain, problem, domain_path, problem_path)`

Submit a planning problem to a solver.

**Parameters:**
- `server` (string): Server URL (e.g., `"https://solver.planning.domains:5001"`)
- `planner` (string): Planner ID (e.g., `"dual-bfws-ffparser"`, `"lama-first"`)
- `domain` (string): PDDL domain text
- `problem` (string): PDDL problem text
- `domain_path` (string, optional): Path to domain file (for plan saving)
- `problem_path` (string, optional): Path to problem file (for plan saving)

**Returns:** Nothing (displays result in a buffer)

### `solver.fetch_planners(server, callback)`

Fetch available planners from a server.

**Parameters:**
- `server` (string): Server URL
- `callback` (function): `function(planners, error)` where planners is an array of `{id, description}`

---

## Troubleshooting

### Plans showing 0 steps but planner succeeded

If you see "goal already satisfied (0 steps)" but expect a plan:
1. Check if using an old cached version: `:PddlReload`
2. Verify domain and problem files are correctly loaded
3. Check planner output logs (shown at bottom of result buffer)

### Module caching issues

If changes aren't taking effect:
1. Run `:PddlReload` to force reload modules
2. For development, use `./dev-sync.sh` + `:PddlReload` workflow
3. As last resort, restart Neovim

### Connection errors

If solver connection fails:
- Verify internet connection
- Check server URL is correct (`:PddlServers`)
- Try the default server: `https://solver.planning.domains:5001`
- Ensure `curl` is installed: `which curl`

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly using the development workflow
5. Submit a pull request

---

## Acknowledgments

- PDDL specification: [PDDL - The Planning Domain Definition Language](https://planning.wiki/)
- Planning service: [solver.planning.domains](https://solver.planning.domains)
- Inspired by [pddl-workspace](https://github.com/jan-dolejsi/pddl-workspace) for VSCode

---

## License

MIT
