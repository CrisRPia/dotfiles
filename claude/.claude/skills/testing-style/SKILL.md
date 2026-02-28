---
name: testing-style
description: "Testing preferences. Consult this whenever writing, running, or reviewing tests. These opinions are still forming — ask before making testing decisions not covered here."
---

## Status

These preferences are early-stage. The user is actively forming their testing
opinions. When something isn't covered here, ask — don't default to generic
testing advice.

## Don't spam tests

Write few, meaningful tests — not one per method or branch. LLMs tend to test
every implementation detail. That produces test suites nobody can read or
maintain. If the user can't understand a test well enough to trust it, the test
is worthless.

## Test interfaces, not implementations

Tests verify the promises a module makes — its invariants, contracts, and
observable behavior. Not how it achieves them internally. If a refactor that
preserves behavior breaks your tests, the tests were wrong.

## Keep tests simple and declarative

Each test should read as a statement of fact: given this input, expect this
output. When tests need setup helpers or shared utilities, that's fine — reuse
them freely, but name them very explicitly so intent is obvious without reading
the implementation.

## Independent tests

Each test should stand alone. No shared mutable state between tests. A sign of
good architecture is being able to reproduce everything from zero on every test
with decent performance and deterministic results.

## Mocking

Ask the user before introducing mocks. Mocking is often a sign that the code
is too coupled. Acceptable uses: external services, network, filesystem — things
that are slow, nondeterministic, or out of your control. Mocking your own code
to make tests pass usually means the architecture needs fixing, not more mocks.
