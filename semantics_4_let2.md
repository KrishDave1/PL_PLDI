# Semantics Part 4: `let2/` — Refactoring for the Future

---

# FOLDER 5: `semantics/let2/` — Same Language, New Architecture

## Why does this folder exist?

`let2/` doesn't add any new user-facing features. You can write the exact same programs as `let/`. So why bother?

**The problem**: In `let/`, `eval` returns `int`, and the environment stores `int` values:
```ocaml
(* let/ version *)
val eval : expr -> env -> int             ← returns int
type env = ... (string * int) * env       ← stores int
```

This works fine for a language with only integers. But in the NEXT folder (`proc/`), we'll add **functions as values**. A function value (closure) is NOT an `int` — it's something like `Closure("x", body, env)`. Where do we store it? The environment can only hold `int`!

**The solution**: Make everything use `expr` as the value type:
```ocaml
(* let2/ version *)
val eval : expr -> env -> Expression.expr     ← returns expr
type env = ... (string * Expression.expr) * env   ← stores expr
```

Now `IntConst(42)`, `BoolConst(true)`, and later `Closure(...)` can ALL be stored in the same environment and returned from `eval`.

> [!IMPORTANT]
> **This is a pure engineering refactor.** The language doesn't change. The user's programs don't change. Only the internal representation changes — to prepare for closures in `proc/`.

---

## The Three Structural Changes

### Change 1: Unified `expr` type — booleans merged in

**Before (`let/`)** — two separate types:
```ocaml
type bool_expr = Boolean | And | Or | Not          ← separate boolean AST
type expr = Const | Add | Subtract | IfExpr | ...  ← integer AST
```

**After (`let2/`)** — one unified type:
```ocaml
type expr =
  | Id        of string
  | IntConst  of int            (* was Const *)
  | BoolConst of bool           (* was in bool_expr, now merged in *)
  | Add       of expr * expr
  | Sub       of expr * expr    (* was Subtract *)
  | If        of expr * expr * expr  (* condition is now expr, not bool_expr *)
  | Let       of string * expr * expr
  | Not       of expr           (* was in bool_expr *)
  | Or        of expr * expr    (* was in bool_expr *)
  | And       of expr * expr    (* was in bool_expr *)
  | Equals    of expr * expr    (* NEW: e1 = e2 *)
```

**Why merge?** Because `eval` needs to return ONE type. If booleans and integers are separate types, what does `eval` return? With everything as `expr`, it returns `Expression.expr` — which can be `IntConst(42)` or `BoolConst(true)` depending on the expression.

**Bonus: `Equals` is new.** Now you can write `if x = 3 then ...` — comparing integer expressions, not just boolean literals. This was impossible in `if_bool/`.

---

### Change 2: `eval` returns `Expression.expr`, not `int`

[Open interpreter.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let2/interpreter.ml)

**Before (`let/`)**:
```ocaml
let rec eval e env : int =
  | Const(c) -> c                  (* returns int directly *)
  | Add(e1, e2) -> (eval e1 env) + (eval e2 env)   (* int + int *)
```

**After (`let2/`)**:
```ocaml
let rec eval e env : Expression.expr =
  | Expression.IntConst(_) -> e     (* return the expr itself *)
  | Expression.BoolConst(_) -> e
  | Expression.Add(e1, e2) ->
      let e1' = (eval e1 env) and e2' = (eval e2 env) in
      let i1 = (getIntConstValue e1') and i2 = (getIntConstValue e2') in
      Expression.IntConst(i1 + i2)   (* wrap result back in IntConst *)
```

**The thought process**: `eval` no longer returns raw OCaml `int`. It returns `Expression.IntConst(n)` or `Expression.BoolConst(b)`. These are **normal forms** — expressions that can't be reduced further. They ARE the values of the language.

### The extractor functions:

Since `eval` returns `expr`, but `+` needs actual OCaml integers, we need unwrappers:

```ocaml
let getIntConstValue e =
  match e with
    Expression.IntConst(c) -> c
  | _ -> raise (TypeError "not an IntConst")

let getBoolConstValue e =
  match e with
    Expression.BoolConst(b) -> b
  | _ -> raise (TypeError "not a BoolConst")
```

These **extract** the OCaml value from the wrapper. If you call `getIntConstValue` on a `BoolConst`, it's a **type error** — you tried to add a boolean.

---

### Change 3: Environment stores `Expression.expr`

[Open env.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let2/env.ml)

**Before (`let/`)**:
```ocaml
type env = ... of (string * int) * env       ← stores int
```

**After (`let2/`)**:
```ocaml
type env = ... of (string * Expression.expr) * env   ← stores expr
```

Now when we do `let x = 3 in ...`, the environment stores `("x", IntConst(3))` instead of `("x", 3)`. Same value, different wrapper.

**Why this matters for `proc/`**: When we add closures, we'll do `let f = fun x -> x+1 in ...`, and the environment will store `("f", Closure("x", Add(Id("x"), IntConst(1)), env))`. That's an `expr` value — it fits naturally.

---

### Change 4: Evaluator is now a separate module

**Before (`let/`)**: `eval` lived inside `expression.ml`.
**After (`let2/`)**: `eval` moved to `interpreter.ml`.

**Why?** Separation of concerns:
- `expression.ml` defines the **types** (what expressions look like)
- `interpreter.ml` defines the **behavior** (what expressions mean)

This makes the code cleaner as the evaluator gets more complex in `proc/` and `letrec/`.

---

### Change 5: `evaluate.ml` pattern-matches on the result

[Open evaluate.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let2/evaluate.ml)

**Before (`let/`)**: `eval` returns `int`, just print it:
```ocaml
Printf.printf "\n\t = %d\n" (Expression.eval e1 Env.EmptyEnv)
```

**After (`let2/`)**: `eval` returns `expr`, need to check what kind:
```ocaml
let result = (Interpreter.eval e1 Env.EmptyEnv) in
match result with
  Expression.IntConst(n)  -> Printf.printf "\n\t = %d\n" n
| Expression.BoolConst(b) -> Printf.printf "\n\t = %b\n" b
| _ -> failwith "Result can't be a non-normal form."
```

The `_` case should never happen — if `eval` is correct, it always produces a normal form (`IntConst` or `BoolConst`). If it somehow returns `Add(...)` or `Id(...)`, something went very wrong.

---

## Quick Trace: `if 3 = 3 then 42 else 0` (NEW! — uses Equals)

This was impossible in `let/` because there was no way to compare integers in a condition.

```
AST: If(Equals(IntConst(3), IntConst(3)), IntConst(42), IntConst(0))

eval If(Equals(...), IntConst(42), IntConst(0))  env=[]
  → eval Equals(IntConst(3), IntConst(3))  env=[]
      eval IntConst(3) → IntConst(3)
      eval IntConst(3) → IntConst(3)
      getIntConstValue(IntConst(3)) = 3
      getIntConstValue(IntConst(3)) = 3
      3 = 3 → true
      → BoolConst(true)
  → getBoolConstValue(BoolConst(true)) = true
  → true → eval IntConst(42) → IntConst(42)

Result: IntConst(42), printed as "= 42"
```

---

## Summary: What changed and why

| Change | Why |
|--------|-----|
| Booleans merged into `expr` | `eval` needs ONE return type |
| `eval` returns `Expression.expr` | So closures (not int, not bool) can be values too |
| `env` stores `Expression.expr` | So variables can hold closures |
| `eval` moved to `interpreter.ml` | Separation of types vs. behavior |
| `Equals` added | Now `if x = 3 then ...` works |
| `getIntConstValue`/`getBoolConstValue` | Extract OCaml values from `expr` wrappers |

> [!TIP]
> **If you understand `let/`, you already understand `let2/`.** The language is identical. The refactor just changes `int` → `Expression.expr` everywhere to prepare for closures. In `proc/` (next folder), we add `Closure` as one more variant of `expr`, and everything just works because the plumbing is already in place.
