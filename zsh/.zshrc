# --- 1. PERFORMANCE PREAMBLE ---
# Optimize compinit (only check for new completions once a day)
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.m-1) ]]; then
  compinit -C
else
  compinit
fi

# --- 2. PATHS & ENVIRONMENT ---
# Define paths first so tools are findable immediately
export PATH="$HOME/scripts:$PATH"
export DOTNET_ROOT=$HOME/.dotnet
export PNPM_HOME="/Users/cristianrodriguez/Library/pnpm"
export PATH="$PATH:$PNPM_HOME:/Users/cristianrodriguez/.dotnet/tools:$DOTNET_ROOT:$DOTNET_ROOT/tools"

# rust
. "$HOME/.cargo/env"
# rust end

# --- 3. PROMPT (Pure) ---
# Loading this early ensures you see a prompt even if other things take a millisecond
autoload -U promptinit; promptinit
prompt pure
# pure end

# --- 4. STATIC CACHING (The "Eval" Killers) ---
# Running eval $(...) is slow. We check if a static version exists first.
# RUN THESE ONCE IN YOUR TERMINAL: 
# zoxide init zsh --cmd cd > ~/.zoxide_init.zsh
# uv generate-shell-completion zsh > ~/.uv_completion.zsh

# zoxide
[[ -f ~/.zoxide_init.zsh ]] && source ~/.zoxide_init.zsh || eval "$(zoxide init zsh --cmd cd)"
# zoxide end

# uv
[[ -f ~/.uv_completion.zsh ]] && source ~/.uv_completion.zsh || eval "$(uv generate-shell-completion zsh)"
# uv end

# --- 5. COMPLETION & BRIDGES ---
# carapace
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
# Cache this too: carapace _carapace > ~/.carapace_init.zsh
[[ -f ~/.carapace_init.zsh ]] && source ~/.carapace_init.zsh || source <(carapace _carapace)
# carapace end

# --- 6. PLUGINS (Load order matters) ---

# fzf-tab
source ~/.config/fzf-tab/fzf-tab.plugin.zsh
# fzf-tab end

# vi-mode
# Moved up so it doesn't conflict with autosuggestions
source /opt/homebrew/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
# vi end

# autosuggestions
source $HOMEBREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# autosuggestions end

# syntax highlighting
# MUST BE LAST to correctly highlight everything loaded above
source $HOMEBREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# syntax highlighting end

# custom commands
#
# wswitch (git worktree switch OR add) function
# - Location-aware: run from any worktree or bare repo.
# - FZF: Pops up fzf if no branch name is given.
# - Switch: If worktree path already exists, just switches to it.
# - Converts slashes in branch name to underscores for the folder path.
# - Auto-links a shared env file based on '.worktree-config.json'
# - Auto-installs pre-commit hooks.
#
gws() {
    local no_cd=0
    local branch_name="$1"
    local start_point="$2"
    local path_name
    local target_path
    local bare_repo_path
    local bare_repo_parent

    # --- 1. Argument Parsing ---
    if [ "$1" = "-n" ] || [ "$1" = "--no-cd" ]; then
        no_cd=1
        shift # Remove the flag
        branch_name="$1" # Re-assign branch_name
        start_point="$2" # Re-assign start_point
    fi

    # --- 2. Find Git Directories ---
    bare_repo_path=$(git rev-parse --git-common-dir)
    if [ -z "$bare_repo_path" ]; then
        echo "Error: Not a git repository."
        return 1
    fi
    bare_repo_parent=$(dirname "$bare_repo_path")

    # --- 3. FZF Branch Selection ---
    if [ -z "$branch_name" ]; then
        if ! command -v fzf &> /dev/null; then
            echo "Error: fzf is not installed. Please install it."
            echo "Or, run with: wswitch <branch-name>"
            return 1
        fi

        echo "No branch specified. Opening fzf to select..."
        branch_name=$( ( \
            cd "$bare_repo_path" && \
            git for-each-ref --format='%(refname:short)' refs/heads refs/remotes/origin | sed 's/^origin\///' | sort -u \
            ) | fzf --prompt="Select branch: ")

        if [ -z "$branch_name" ]; then
            echo "Aborted."
            return 1
        fi
    fi

    # --- 4. Create Paths ---
    path_name=${branch_name//\//_}
    target_path="${bare_repo_parent}/${path_name}"

    # --- 5. SWITCH-OR-ADD LOGIC ---
    if [ -d "$target_path" ]; then
        # Path EXISTS. Just CD into it.
        echo "Worktree '$path_name' already exists."
    else
        # --- 6. Path does NOT exist. Run the 'add' logic. ---
        if [ -z "$start_point" ]; then
            if [ -f "$(git rev-parse --git-dir)/HEAD" ]; then
                start_point=$(git symbolic-ref --short HEAD)
                echo "No start-point specified. Defaulting to current worktree branch: $start_point"
            else
                start_point="master" # <-- CHANGE 'master' to 'main' if that's your default
                echo "No start-point specified (and in bare repo). Defaulting to: $start_point"
            fi
        fi

        if ! ( \
            cd "$bare_repo_path"; \
            if git rev-parse --verify --quiet "$branch_name" > /dev/null; then \
                if [ -n "$2" ]; then \
                    echo "Note: Branch '$branch_name' already exists. Ignoring start-point '$start_point'."; \
                    fi; \
                    echo "Branch '$branch_name' exists. Creating worktree at $target_path..."; \
                    git worktree add "$target_path" "$branch_name"; \
                else \
                    echo "Branch '$branch_name' not found. Creating new branch from '$start_point'..."; \
                    git worktree add -b "$branch_name" "$target_path" "$start_point"; \
                    fi \
                    ); then
        echo "Error: 'git worktree add' failed."
        return 1
        fi
    fi

    # --- 7. Link Configured Shared Env File (JSON) ---
    local config_file="${bare_repo_parent}/.worktree-config.json"
    if [ -f "$config_file" ]; then
        if ! command -v jq &> /dev/null; then
            echo "Error: jq is not installed. Cannot read .worktree-config.json"
            return 1
        fi

        local env_source=$(jq -r '.sharedEnv.source // empty' "$config_file")
        local env_target=$(jq -r '.sharedEnv.target // empty' "$config_file")

        if [ -n "$env_source" ] && [ -n "$env_target" ]; then
            local shared_env_file_abs_path="${bare_repo_parent}/${env_source}"
            local target_env_file_abs_path="${target_path}/${env_target}"

            if [ -f "$shared_env_file_abs_path" ]; then
                if [ -e "$target_env_file_abs_path" ]; then
                    : # Target file/link already exists, do nothing
                else
                    # *** THIS IS THE FIX ***
                    # Calculate the directory depth of the target
                    local depth=$(echo "$env_target" | grep -o "/" | wc -l)
                    local relative_prefix=""
                    for ((i=0; i<=$depth; i++)); do
                        relative_prefix+="../"
                    done

                    local relative_link_target="${relative_prefix}${env_source}"

                    echo "Creating link: ${env_target} -> ${relative_link_target}"
                    # Ensure target directory exists
                    mkdir -p "$(dirname "$target_env_file_abs_path")"
                    # Create the correct relative symlink
                    ln -s "$relative_link_target" "$target_env_file_abs_path"
                fi
            else
                echo "Warning: Shared env file not found at $shared_env_file_abs_path"
            fi
        fi
    fi

    # --- 8. CD into worktree ---
    if [ $no_cd -eq 0 ]; then
        echo "Changing directory to $target_path..."
        cd "$target_path"

        # --- 9. Auto-install hooks ---
        if [ -f ".pre-commit-config.yaml" ]; then
            echo "Found pre-commit config, running install..."
            prek install
        fi
    fi
}
export PATH="$(brew --prefix ruby)/bin:$PATH"


# Load Angular CLI autocompletion.
source <(ng completion script)

export PATH="/Users/cristianrodriguez/Library/Python/3.14/bin:$PATH"

# Vibe coding
export ENABLE_LSP_TOOL=1
