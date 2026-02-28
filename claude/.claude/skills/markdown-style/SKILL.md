---
name: markdown-style
description: "Markdown style preferences for files. Consult this whenever writing or editing markdown files (.md) to match the user's established patterns."
---

## Headers

ATX style (`#`) only, no setext underlines. Maximum 3–4 levels deep. One blank
line before and after each header. No emoji in headers.

## Lists

Use `-` for unordered lists, not `*` or `+`. Use `1. 2. 3.` for ordered lists
when sequence matters. Indent nested lists with 4 spaces.

Short items: no trailing period. Full sentences: period required.

## Line wrapping

Wrap lines at roughly 80 characters. It's not a strict rule — don't break a
line awkwardly to hit exactly 80. The goal is readable source text, not just
rendered output.

## Code blocks

Always fenced with triple backticks. Always include the language tag (`python`,
`bash`, `toml`, etc.). Never use indented code blocks.

## Emphasis

Use markdown as a content describer, not a rendering engine. Emphasis adds
meaning — use it sparingly. If everything is bold, nothing is. Don't bold list
item labels just because they're labels (`- thing: description`, not
`- **thing**: description`). Reserve bold for genuinely important terms that
need to stand out. Italic for secondary notes or asides.

## Links

Inline style: `[text](url)`. Use relative paths for internal docs
(`./docs/README.md`). No reference-style links.

## Tables

Clean pipe syntax with header separator. Align columns for readability.

## Prose style

Terse and imperative for instructions — no filler. Complete sentences with
periods for explanations. Don't over-explain what code examples already show.

## READMEs

READMEs are manuals, not ads. They exist to be useful — what the project does,
how to set it up, how to use it. No sales pitch, no hype, no "elegant
solution" language. Treat the project as a tool and the README as its
documentation. Skip badges, shields, and promotional framing unless the user
explicitly asks for it.

## Don't

- Emoji in headers or body text
- HTML in markdown unless absolutely necessary
- Promotional tone in documentation
