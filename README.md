# dotfiles

Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Setup on a new machine

```bash
# Prerequisites
brew install stow

# Clone
git clone git@github.com:CrisRPia/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Stow everything
stow -t ~ zsh git aerospace barik nushell linearmouse

# nvim and claude need manual symlinks
ln -s ~/dotfiles/nvim/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/claude/.claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/dotfiles/claude/.claude/settings.json ~/.claude/settings.json
ln -s ~/dotfiles/claude/.claude/skills ~/.claude/skills
```

If files already exist, use `stow --adopt` to replace them (moves originals into the repo).

## Backing up changes

```bash
cd ~/dotfiles
git add -A && git commit -m "update" && git push
```

## Packages

| Package | What |
|---|---|
| `zsh` | `.zshrc`, `.zshenv`, `.zprofile` |
| `git` | `.gitconfig`, `.config/git/ignore` |
| `aerospace` | Tiling window manager config |
| `barik` | Status bar config |
| `nushell` | Nushell shell config |
| `linearmouse` | Mouse/trackpad settings |
| `nvim` | Neovim config (symlinked as directory) |
| `claude` | Claude Code global settings and instructions |

## Adding a new package

```bash
mkdir -p ~/dotfiles/<name>
# Mirror the home directory structure inside it, e.g.:
# ~/dotfiles/foo/.config/foo/config.toml
# Then:
stow -t ~ <name>
```
