---
name: python-style
description: "Code style preferences for Python. Consult this whenever writing, reviewing, or modifying Python code to match the user's established patterns."
---

## Philosophy

Write typesafe, correct code. Prefer simplicity over cleverness, immutability
over mutation, loud crashes over silent wrong behavior. Push logic into pure
functions, isolate side effects at the edges, and let the type system carry as
much meaning as possible so the code documents itself.

## Type safety

Annotate everything: function signatures, class attributes, variables where the
type isn't obvious. The user runs basedpyright — fix every diagnostic. For
scoping behavior in other people's repos, defer to the "Working in existing
codebases" section in CLAUDE.md.

Annotate class attributes in the class body, not just in `__init__`. If you see
redundant in-function annotations compensating for a loose return type upstream,
fix the source — don't paper over it locally.

Prefer `object` over `Any`. `Any` disables the type checker and is almost never
correct. If something truly accepts anything, `object` is the honest type. The
only legitimate `Any` is interop with untyped third-party code you can't fix.

## Modern syntax

Use builtin generics (`list[str]`, `dict[str, int]`), union syntax
(`str | None`), `Self`, `-> None` on void methods, and `collections.abc` types
(`Sequence`, `Mapping`, `Iterable`) in parameters where you don't need a
concrete type. Never import `List`, `Dict`, `Tuple`, or `Optional` from
`typing`.

Use the `type` statement for aliases (PEP 695). It supports lazy evaluation and
recursive definitions:

```python
type JSON = str | int | float | bool | None | list[JSON] | dict[str, JSON]
```

Be aware `type` aliases can't be used everywhere plain assignments can (e.g.,
variadic generics). Fall back to assignment when you hit these edges.

Use PEP 695 syntax for generics: `class Stack[T]:`,
`def first[T](items: list[T]) -> T:`.

## Generics

Give type parameters descriptive names. `TInput`, `TResponse`, `TNode` — not
`T`, `U`, `V`.

Prefer bounded generics over `@overload` when the return type mirrors the input:

```python
# Prefer this
def process[TInput: str | Doc](text: TInput) -> TInput: ...

# Over this
@overload
def process(text: str) -> str: ...
@overload
def process(text: Doc) -> Doc: ...
```

Reserve `@overload` for cases generics can't express (e.g., a `Literal` flag
selecting different return types).

**Variadic generics** (`*Ts`): use for heterogeneous `*args` and shape-aware
containers. Always unpack — `*args: *Ts`, not `*args: Ts`. One `TypeVarTuple`
per parameter list, `*args` only (not `**kwargs`):

```python
def args_to_tuple[*Ts](*args: *Ts) -> tuple[*Ts]:
    return args

class NDArray[DType, *Shape]: ...

def add_batch[*Shape](x: Array[*Shape]) -> Array[Batch, *Shape]: ...
```

**ParamSpec** (`**P`): use to type decorators that preserve the wrapped
function's signature. Access components only as `*args: P.args` and
`**kwargs: P.kwargs`. Use `Concatenate` to prepend fixed parameters:

```python
def logged[**P, TReturn](f: Callable[P, TReturn]) -> Callable[P, TReturn]:
    @wraps(f)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> TReturn:
        print(f"Calling {f.__name__}")
        return f(*args, **kwargs)
    return wrapper

def with_context[**P](
    f: Callable[Concatenate[Context, P], None]
) -> Callable[P, None]:
    @wraps(f)
    def wrapper(*args: P.args, **kwargs: P.kwargs) -> None:
        f(Context(), *args, **kwargs)
    return wrapper
```

## Semantic types

Use the type system to encode meaning. Don't accept `int` when you mean a
duration — accept `timedelta`. Don't accept `str` when you mean a date — accept
`datetime`. The type tells you what something *is*, not just how it's stored.

When a primitive has shared domain meaning, give it a name:
`type BitwiseEncodedUserId = int`. The signature becomes self-documenting. If
you feel the need to document what parameters are, the types aren't expressive
enough — reach for `NewType`, enums, or Pydantic constrained types before
reaching for a docstring.

## Enums and Literals

Use `StrEnum` / `IntEnum` across module boundaries and public APIs — if the
linter passes, the reviewer knows the variant is valid. `Literal["a", "b"]` is
fine for local flags where ergonomics matter, but the tradeoff is that reviewers
can't verify variants at a glance.

Enums pair naturally with `match`/`case` and `assert_never` for exhaustiveness.
For discriminated unions in Pydantic models, prefer enums as the discriminator.

## Naming

Long names are good. A variable's name should communicate its intention, not
just its structure — the type system already handles that, so don't prefix with
`str_` or `dict_`. When someone jumps to a definition without surrounding
context, the name alone should tell them what they're looking at.

The exception is when something represents an external concept. If you're
wrapping a REST API, mirror the API's naming in your models and endpoints so
it's easy to grep between your code and the external docs.

## Code structure

Don't run behavior at module level. Every program should have a `main()`
function — nothing important in global scope. Global scope is for definitions
(constants, types, classes, functions) and assertions over global state that
fail immediately if invariants are broken — ad-hoc tests upholding guarantees
of constants.

Medium-sized functions are the sweet spot — all the context visible without
scrolling. Don't over-extract into tiny functions that force you to jump around.

Large functions signal a need to break up. Look for natural pipeline stages:
each step takes input, produces output, the next step picks it up. Push toward
pure functions — take input, return output, no side effects. Isolate IO and
state mutation at the edges.

## Function signatures

Avoid `*args` and `**kwargs` outside of decorators. They erase type information
and make it hard to extend an interface later — adding a parameter means auditing
every call site to make sure it's not silently swallowed. Spell out the
parameters explicitly. The only good use is in decorator wrappers where you're
forwarding an unknown signature via `ParamSpec`.

## Decorators

Always use `@functools.wraps(f)` on the inner wrapper. It preserves
`__name__`, `__doc__`, `__annotations__`, `__type_params__`, and sets
`__wrapped__`. Type decorators with `ParamSpec` so the signature is preserved
for type checkers too, not just at runtime.

## Comments and documentation

Don't over-document. Good code describes itself. Comments are only for
justifying something that looks wrong but is intentional — workarounds, API
quirks, non-obvious external constraints.

Docstrings define a function's contract so callers don't need to read the
implementation: what it does, what it expects, what it returns. No filler. If a
signature with expressive types already communicates the contract, skip the
docstring entirely — a redundant docstring is worse than none because it rots.

## Pattern matching

Reach for `match`/`case` liberally. It's the preferred way to destructure
dicts, dispatch on type, handle unions, and replace if/elif chains.

Mapping patterns destructure dicts safely (no KeyError risk). Class patterns
replace `isinstance` chains — `ClassName()` in a pattern narrows and
destructures in one step. `Type() as var` narrows and captures simultaneously.

```python
match response:
    case {"status": 200, "data": {"items": [*items]}}:
        process(items)
    case {"status": int() as code, "error": str() as msg} if code >= 400:
        handle_error(code, msg)
    case _:
        raise UnexpectedResponse(response)

match event:
    case Click(position=pos):
        handle_click(pos)
    case KeyPress(key="q"):
        quit()
```

For exhaustiveness on unions, use `assert_never` so basedpyright catches
missing cases:

```python
case other:
    assert_never(other)
```

For open-ended matches where unexpected values are possible at runtime, use
`case _:` with a raise. Dataclasses support class patterns automatically via
`__match_args__`.

## Defensive programming

Assert assumptions instead of papering over them with defaults:

```python
assert user is not None
assert isinstance(event, ClickEvent)
```

Assertions are documentation that crashes when wrong. They make invariants
explicit and catch violations early instead of letting bad state propagate.
Use them for internal invariants — things that should be true if the code is
correct. For external input, use proper validation. Don't fear errors — a loud
crash beats silently doing the wrong thing.

## Error handling

Don't add try/except just because something *could* throw. Letting exceptions
propagate is often correct — there's usually a global handler, or the caller is
better positioned to decide. Unnecessary error handling is noise.

When you do handle errors:
- Use try/except for external state (filesystem, network, untrusted input)
  where failure is expected and needs local handling.
- Keep try blocks minimal — only the operation that can raise.
- Catch specific exceptions. Bare `except:` and `except Exception:` are only
  acceptable at top-level entry points.
- No silent `pass` handlers. Log with context, re-raise with
  `raise X from e`, or return a documented default.

For local values, prefer `match`/`case` with structural patterns, or
conditional checks (`if`, `in`, `hasattr()`). Catching `KeyError`,
`AttributeError`, or `TypeError` as control flow is a code smell — it usually
means you should be using pattern matching, `dict.get()`, or `isinstance()`.

## Comprehensions

Prefer comprehensions when short and clear. Don't force functional style — if
you need mutable state, intermediate variables, or multi-step logic, use a
loop. No nesting beyond one level. Loops are also easier to debug since you
can drop a `print` in the body.

## Pydantic

Pydantic is the preferred tool for data modeling, validation, and
serialization. Use it by default.

**Data classes**: prefer `BaseModel` or `pydantic.dataclasses.dataclass` over
stdlib `@dataclass`. The validation guarantee is worth the tradeoff — simplicity
and correctness over raw performance. Favor immutability: `frozen=True` or
`model_config = ConfigDict(frozen=True)` by default. Reach for stdlib
`@dataclass` only when you genuinely need to avoid the dependency.

**Serialization**: `BaseModel` when data crosses a boundary (API, config,
storage). `TypedDict` when the value is internal and must stay a plain dict.
Use `TypeAdapter` for composite types that aren't a single model. Repeat the
type as both generic parameter and argument for type safety:

```python
adapter = TypeAdapter[list[dict[str, tuple[MyModel, int]]]](
    list[dict[str, tuple[MyModel, int]]]
)
data = adapter.validate_json(raw)
```

**`@validate_call`**: use on functions that receive external/untyped input. It
coerces arguments from annotations (e.g., `"2024-01-01"` → `date`), supports
`Field()` constraints via `Annotated`, and works with async. For hot paths with
trusted input, access `.raw_function`.

When dicts have an assumed key structure — literal keys used consistently,
multiple functions passing the same shape — replace them with a model or
`TypedDict`.

## Imports

All imports at the top of the file. Don't use lazy imports preemptively — only
reach for in-function imports when a circular import actually breaks things.
`TYPE_CHECKING` blocks are fine for runtime cycles, but try a normal top-level
import first. Import concrete types from the libraries that define them
(`Language`, `Doc`, `Tensor`) rather than vague stand-ins.

## File paths

Use `pathlib.Path`, not `os.path`. For files relative to the current module:

```python
path = Path(__file__).parent / "./data/config.json"
```

The `"./"` prefix lets editors resolve the path for navigation. Prefer
`.read_text()` / `.write_text()` over `open()` — one expression, no context
manager boilerplate.

## Strings and logging

f-strings always. Not `.format()`, not `%`.

Multiline strings: triple-quote with `textwrap.dedent`:

```python
query = dedent("""\
    SELECT *
    FROM users
    WHERE active = true
""")
```

For debug output, the `=` specifier makes values greppable:

```python
print(f"{user_id = }")  # user_id = 42
```

Logs should be infrequent, clear, and useful. Every log line should tell you
something you couldn't easily figure out otherwise.

## Walrus operator

Avoid `:=`. It hides assignments and widens lines. Assign on the line above.
The only acceptable use is in a comprehension filter:
`[y for x in items if (y := transform(x)) is not None]`.

## Monkey-patching

Avoid it. If it seems like the only option, discuss it first — there's usually
a better way. If it's genuinely needed, comment why. This is exactly the kind
of thing that looks wrong and needs justification.
