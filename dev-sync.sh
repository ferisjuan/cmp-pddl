#!/bin/bash
# Development sync script - copies changes to lazy.nvim installation

echo "Syncing cmp-pddl to lazy.nvim..."
cp -r /Users/juan/wsp/cmp-pddl/lua/cmp_pddl/*.lua ~/.local/share/nvim/lazy/cmp-pddl/lua/cmp_pddl/
cp /Users/juan/wsp/cmp-pddl/plugin/cmp_pddl.lua ~/.local/share/nvim/lazy/cmp-pddl/plugin/
echo "✓ Synced. Run :PddlReload in Neovim to reload modules."
