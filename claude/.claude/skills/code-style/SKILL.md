---
name: code-style
description: "General code style preferences that apply across all languages. Consult this as a fallback whenever writing, reviewing, or modifying code in a language that doesn't have its own style skill."
---

## Philosophy

Write correct code. Prefer simplicity over cleverness, immutability over
mutation, loud crashes over silent wrong behavior. Push logic into pure
functions, isolate side effects at the edges, and let the type system carry as
much meaning as possible so the code documents itself.

## Type safety

Annotate everything the language allows: function signatures, class/struct
fields, variables where the type isn't obvious. Use the strictest type checker
available and fix its diagnostics — don't disable or ignore them. Prefer
narrow, precise types over escape hatches (`any`, `object`, `void*`).

## Semantic types

Use the type system to encode meaning. Don't accept a bare `int` when you mean
a duration, or a `string` when you mean a date. When a primitive has shared
domain meaning, give it a named type — the signature becomes self-documenting.
If you feel the need to document what parameters are, the types aren't
expressive enough.

## Enums

Prefer enums over magic strings/numbers across module boundaries and public
APIs. For local flags where ergonomics matter, literal types are fine.

Always use exhaustive matching. Most modern languages have a way to enforce
that every branch is handled at compile time or lint time — `assert_never` in
Python, `never` in TypeScript, `match` exhaustiveness in Rust/Swift/Kotlin.
Use it. An unhandled branch should not compile, not pass linting, and not be
silently ignored at runtime. If a new variant is added, every switch point
should immediately break until it's addressed.

## Naming

Long names are good. A name should communicate intention, not structure — the
type system handles structure. When someone jumps to a definition without
surrounding context, the name alone should tell them what they're looking at.

The exception is when wrapping an external concept. Mirror the external naming
(API, protocol, spec) so it's easy to grep between your code and the external
docs.

## Code structure

Don't run behavior at module/file level. Every program should have an explicit
entry point — nothing important in global scope. Global scope is for
definitions (constants, types, functions) and compile-time or load-time
assertions over invariants.

Medium-sized functions are the sweet spot — all the context visible without
scrolling. Don't over-extract into tiny functions that force you to jump
around. Large functions signal a need to break up along natural pipeline
stages: each step takes input, produces output, the next step picks it up.

Push toward pure functions — take input, return output, no side effects.
Isolate IO and state mutation at the edges.

## Iteration

Prefer iterator/pipeline patterns over C-style index loops. Chained iterators
(LINQ in C#, `.iter()` chains in Rust, streams in Java, Sequence in Kotlin)
eliminate off-by-one errors, remove mutable counters, and make intent explicit
— "filter then transform" reads clearer than manual index juggling. When the
language has good iterator ergonomics, use them liberally.

When the body needs mutable state or multi-step logic, a plain loop is fine —
but iterate over the collection directly, not over indices.

More broadly, prefer declarative code that says *what* you want over
imperative code that spells out *how*. Fewer moving parts, fewer places to
get wrong.

## Function signatures

Spell out parameters explicitly. Avoid variadic/rest arguments outside of
generic wrappers — they erase type information and make interfaces hard to
extend. Every parameter should be visible in the signature.

## Immutability

Default to immutable data. Reach for mutable state only when there's a clear
performance or ergonomic reason. Frozen/readonly by default, mutable by
exception.

## Defensive programming

Assert assumptions instead of papering over them with defaults. Assertions are
documentation that crashes when wrong. Use them for internal invariants — things
that should be true if the code is correct. For external input, use proper
validation. A loud crash beats silently doing the wrong thing.

## Error handling

Don't add error handling just because something *could* fail. Letting errors
propagate is often correct — there's usually a handler higher up, or the caller
is better positioned to decide.

When you do handle errors:
- Only at boundaries with external state (filesystem, network, untrusted input)
  where failure is expected and needs local handling.
- Keep the guarded region minimal — only the operation that can fail.
- Catch specific errors, not broad categories.
- No silent swallowing. Log with context, re-raise with cause, or return a
  documented default.

## Comments and documentation

Don't over-document. Good code describes itself. Comments justify things that
look wrong but are intentional — workarounds, API quirks, non-obvious external
constraints.

Documentation on functions defines the contract so callers don't need to read
the implementation. No filler. If a signature with expressive types already
communicates the contract, skip it — redundant docs rot.

## Imports and dependencies

All imports at the top. Don't use lazy imports preemptively — only when a
real problem (circular dependency, startup cost) forces it. Import concrete
types from the libraries that define them.

## Strings

Use the language's interpolation syntax (f-strings, template literals,
string interpolation). Not concatenation, not format functions.

## JavaScript

If writing JavaScript, first consider whether TypeScript is an option. If it
is, use TypeScript. If JavaScript is forced (existing project, tooling
constraint), write typesafe JSDoc annotations as if you were writing
TypeScript — `@param`, `@returns`, `@typedef`, `@type`. The code should
type-check with `// @ts-check` or a tsconfig with `checkJs: true`.

## Avoid

- Monkey-patching. Discuss first if it seems like the only option.
- Over-engineering. Don't design for hypothetical future requirements.
- Silent failures. Every error should be visible somewhere.
- Stringly-typed code. If a value has a known set of options, use a type.
