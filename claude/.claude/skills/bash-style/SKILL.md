---
name: bash-style
description: "Code style preferences for Bash. Consult this whenever writing or editing shell scripts to match the user's established patterns."
---

## Philosophy

Bash is glue. It connects programs, moves files, and runs pipelines. It is not
a general-purpose language. Write the simplest script that does the job, crash
on errors, and get out.

## Defaults

Every script starts with:

```bash
#!/usr/bin/env bash
set -euo pipefail
```

`-e` exits on errors, `-u` on undefined variables, `-o pipefail` catches
failures in pipe midpoints. This eliminates most guard clauses — let it fail
loudly.

## Structure

Use functions to split things up when code naturally forms a pipeline — parse,
transform, output. No need for highly modular design, but don't write a wall
of commands either.

Keep a `main` function as the entry point:

```bash
main() {
    ...
}

main "$@"
```

For longer scripts, use section separators:

```bash
# --- Configuration ---
# --- Main Logic ---
```

## Variables and quoting

Always double-quote variables: `"$var"`, `"$@"`, `"${array[@]}"`. Unquoted
variables are the single most common source of bash bugs.

Use `local` for variables inside functions.

## Conditionals

Use `[[ ]]`, not `[ ]`. Use `$()` for command substitution, not backticks.

## Style

Prefer explicit commands over clever bash tricks. Bash syntax is awful — don't
make it worse with obscure parameter expansions, nested substitutions, or
brace gymnastics. If a command does what you need, use the command.

Function names in snake_case.

## Comments

Don't spam comments, but bash can become unreadable fast. Comment when the
intent isn't obvious from the command itself — especially for pipelines,
redirections, and flags that aren't self-explanatory.

## Shellcheck

Write shellcheck-clean scripts. Treat shellcheck warnings like type checker
diagnostics — fix them, don't ignore them.

## When to stop using bash

When a script starts needing:
- arrays or associative arrays beyond trivial use
- string manipulation beyond simple substitution
- complex control flow or error handling beyond set -euo pipefail
- data transformation or structured output

...stop. Ask the user what to use instead — nushell for data pipelines, Python
for a small project (set up properly with uv), Rust for a CLI tool, etc. Don't
assume.
