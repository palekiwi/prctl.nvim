# prctl.nvim

A Neovim plugin that integrates GitHub pull requests with Telescope, allowing you to view and checkout PRs directly from your editor.

## Features

- List pull requests for the current repository
- Display PRs in a Telescope picker with formatted columns
- Checkout PRs with a single keypress
- Clear error messages and validations

## Requirements

- **Neovim 0.10+** (uses `vim.system()` API)
- **[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)** - Fuzzy finder UI
- **[GitHub CLI (gh)](https://cli.github.com/)** - GitHub API integration

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/prctl.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  cmd = 'Prctl',
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/prctl.nvim',
  requires = {
    'nvim-telescope/telescope.nvim',
  },
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'nvim-telescope/telescope.nvim'
Plug 'yourusername/prctl.nvim'
```

## Setup

### GitHub CLI Authentication

Before using prctl.nvim, ensure you're authenticated with GitHub CLI:

```bash
gh auth login
```

## Usage

### Basic Usage

In a git repository, run:

```vim
:Prctl
```

This will:
1. Fetch pull requests for the current repository
2. Open a Telescope picker showing PRs
3. Allow you to checkout a PR by pressing `<CR>`

### Keybindings (in Picker)

- `<CR>` - Checkout selected PR
- `<C-n>` / `<C-p>` - Navigate through PRs
- `<Esc>` / `<C-c>` - Close picker
- Type to search/filter PRs

### Display Format

PRs are displayed with tab-separated columns:

```
#123    Add dark mode support             @username       feature/dark-mode → main
#124    Fix authentication bug            @contributor    fix/auth → main
#125    Update documentation              @docs-team      docs/update → develop
```

## Limitations

- Shows up to 50 most recent PRs
- No preview window (planned for future release)
- No filtering options by author, labels, etc. (planned for future release)
- Cannot create or merge PRs (planned for future release)

## Troubleshooting

### "GitHub CLI (gh) not installed"

Install GitHub CLI from https://cli.github.com/

### "Failed to fetch PRs: ..."

Run `gh auth login` to authenticate with GitHub.

### "Cannot checkout PR: You have uncommitted changes"

Commit or stash your changes before checking out a PR:

```bash
git stash
# or
git commit -am "WIP"
```

### "Not in a git repository"

Navigate to a git repository before running `:Prctl`.

## Development

This plugin uses Nix for development environment setup:

```bash
nix develop
```

## License

MIT

## Contributing

Issues and pull requests are welcome!
