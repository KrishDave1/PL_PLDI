# Semantics Part 3: `let/` — Variables and the Environment

---

# FOLDER 4: `semantics/let/` — The Biggest Conceptual Leap

## Why do we need this?

In `if_bool/`, every value is **hardcoded** in the program text. You write `3 + 4`, and that's it — there's no way to **name** things and reuse them. But real programs need:

```
let x = 3 + 4 in
let y = x * 2 in
x + y
```

Variables let you **name intermediate results**, reuse values, and build complex programs from simple parts.

But variables create a fundamental problem: **when `eval` sees `x`, how does it know what value `x` has?**

In `const/`, `eval` took just one argument: the expression. That was enough because every value was right there in the tree. Now we need a **second piece of information**: a mapping from names to values. This mapping is called the **environment**.

> [!IMPORTANT]
> **This is the single biggest change in the codebase.** In `const/`, `if/`, and `if_bool/`, `eval` was a pure function of the expression alone: `eval : expr -> int`. Starting from `let/`, eval needs context: `eval : expr -> env -> int`. Every subsequent folder (`let2/`, `proc/`, `letrec/`) keeps the environment — it just carries richer values in it.

---

## What changed from `if_bool/`?

| What's new | Why |
|---|---|
| **`env.ml`** — a whole new module | Stores the name→value mapping |
| `Id of string` in the AST | So you can write `x` (a variable reference) |
| `LetExpr of string * expr * expr` in the AST | So you can write `let x = e1 in e2` |
| `eval` now takes `env` parameter | Every evaluation happens in the context of an environment |
| `evaluate.ml` passes `EmptyEnv` | The program starts with no variables defined |

---

## FILE 1: `env.ml` — The Environment (Brand New Module)

[Open env.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/env.ml)

### Why a separate module?

The environment is a **fundamental data structure** that every part of the interpreter needs. Putting it in its own module keeps things clean and lets us swap the implementation later (which is exactly what `let2/` does).

### The type:

```ocaml
type env =
    EmptyEnv                              (* no bindings *)
  | NonEmptyEnv of (string * int) * env   (* (name, value) :: rest *)
```

**It's a linked list.** Each node is a `(name, value)` pair pointing to the rest of the environment. Newest bindings go at the front.

### Visualising an environment:

After executing `let x = 3 in let y = 7 in ...`, the environment looks like:

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ y = 7    │ →  │ x = 3    │ →  │ EmptyEnv │
└──────────┘    └──────────┘    └──────────┘
  (front)         (older)         (end)
```

In code: `NonEmptyEnv(("y", 7), NonEmptyEnv(("x", 3), EmptyEnv))`

### The three operations:

```ocaml
(* 1. Create empty env *)
let emptyEnv () = EmptyEnv

(* 2. Add a binding at the FRONT *)
let addBinding x v env =
  NonEmptyEnv((x, v), env)

(* 3. Look up a variable — search front to back *)
let rec apply x env : int =
  match env with
    EmptyEnv -> raise Not_found                    (* variable doesn't exist! *)
  | NonEmptyEnv((vname, value), env') ->
    if x = vname then value                        (* found it! *)
    else (apply x env')                            (* keep searching *)
```

### Why front-to-back search? — Shadowing

If you write:
```
let x = 3 in
let x = 100 in
x + 1
```

The environment becomes:
```
┌──────────┐    ┌──────────┐    ┌──────────┐
│ x = 100  │ →  │ x = 3    │ →  │ EmptyEnv │
└──────────┘    └──────────┘    └──────────┘
```

When `apply "x" env` searches front-to-back, it finds `x = 100` first and stops. The old `x = 3` is **shadowed** — it still exists in the list, but it's unreachable. This is called **lexical scoping**.

---

## FILE 2: `expression.ml` — Variables + Let Bindings

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/expression.ml)

### The AST type (what changed from if_bool/):

```diff
 type expr =
+  | Id       of string                    (* NEW: variable reference *)
   | Const    of int
   | Add      of expr * expr
   | Subtract of expr * expr
   | IfExpr   of bool_expr * expr * expr
+  | LetExpr  of string * expr * expr      (* NEW: let x = e1 in e2 *)
```

**`Id("x")`** — "look up the variable named x in the environment"
**`LetExpr("x", e1, e2)`** — "evaluate e1, bind the result to x, then evaluate e2"

### The eval function — NOW TAKES `env`:

```diff
-let rec eval e =
+let rec eval e env =
   match e with
+  | Id(s) -> Env.apply s env              (* NEW: look up variable *)
   | Const(c) -> c
   | Add(e1, e2) ->
-      let i1 = (eval e1) and i2 = (eval e2) in
+      let i1 = (eval e1 env) and i2 = (eval e2 env) in    (* pass env through *)
       i1 + i2
   | Subtract(e1, e2) ->
+      let i1 = (eval e1 env) and i2 = (eval e2 env) in
       i1 - i2
   | IfExpr(b, e1, e2) ->
+      if (bool_eval b) = true then (eval e1 env) else (eval e2 env)
+  | LetExpr(vname, e1, e2) ->             (* NEW *)
+      let env' = (Env.addBinding vname (eval e1 env) env) in
+      (eval e2 env')
```

### Understanding `LetExpr` — The Recipe

`let x = e1 in e2` is evaluated in three steps:

```
Step 1:  Evaluate e1 in the CURRENT environment  →  get a value v
Step 2:  Create a NEW environment = current env + (x → v)
Step 3:  Evaluate e2 in the NEW environment  →  that's the result
```

In code:
```ocaml
| LetExpr(vname, e1, e2) ->
    let env' = (Env.addBinding vname (eval e1 env) env) in   (* steps 1+2 *)
    (eval e2 env')                                            (* step 3 *)
```

> [!IMPORTANT]
> **e2 gets a DIFFERENT environment than e1.** e1 is evaluated in the old env (before x exists). e2 is evaluated in the new env (where x is defined). This is why `let x = x + 1 in ...` would fail if x wasn't already defined — e1 can't see the binding it's creating.

### Understanding `Id` — Variable Lookup

```ocaml
| Id(s) -> Env.apply s env
```

"Find the name `s` in the environment and return its value." If `s` isn't in the environment, `Env.apply` raises `Not_found` — an **unbound variable error**.

---

## Detailed Trace: `examples/10.txt`

```
let x = 20       in
let y = 10       in
let sum1 = x + y in
let x = 100      in
let z = 5        in
  sum1 - z + x
```

**Expected result**: `sum1 - z + x` = `30 - 5 + 100` = `125`

Let's trace step by step:

```
═══ Step 1: eval (LetExpr("x", Const(20), ...)) env=[]
  eval Const(20) in env=[]  →  20
  env' = [x=20]
  Continue with body in env=[x=20]

═══ Step 2: eval (LetExpr("y", Const(10), ...)) env=[x=20]
  eval Const(10) in env=[x=20]  →  10
  env' = [y=10, x=20]
  Continue with body in env=[y=10, x=20]

═══ Step 3: eval (LetExpr("sum1", Add(Id("x"), Id("y")), ...)) env=[y=10, x=20]
  eval Add(Id("x"), Id("y")) in env=[y=10, x=20]
    eval Id("x")  →  apply "x" [y=10, x=20]  →  20
    eval Id("y")  →  apply "y" [y=10, x=20]  →  10
    20 + 10 = 30
  env' = [sum1=30, y=10, x=20]
  Continue with body in env=[sum1=30, y=10, x=20]

═══ Step 4: eval (LetExpr("x", Const(100), ...)) env=[sum1=30, y=10, x=20]
  eval Const(100) in env=[sum1=30, y=10, x=20]  →  100
  env' = [x=100, sum1=30, y=10, x=20]     ← x=100 SHADOWS x=20!
  Continue with body in env=[x=100, sum1=30, y=10, x=20]

═══ Step 5: eval (LetExpr("z", Const(5), ...)) env=[x=100, sum1=30, y=10, x=20]
  eval Const(5)  →  5
  env' = [z=5, x=100, sum1=30, y=10, x=20]
  Continue with body in env=[z=5, x=100, sum1=30, y=10, x=20]

═══ Step 6: eval (Add(Subtract(Id("sum1"), Id("z")), Id("x")))
  in env=[z=5, x=100, sum1=30, y=10, x=20]

  eval Id("sum1")  →  apply "sum1" env  →  30
  eval Id("z")     →  apply "z" env     →  5
  eval Id("x")     →  apply "x" env     →  100  ← finds x=100, not x=20!

  (30 - 5) + 100 = 125 ✅
```

### Key observations from this trace:

1. **Environments grow** — each `let` adds one binding to the front
2. **Shadowing works** — the second `let x = 100` doesn't destroy `x=20`, it just hides it
3. **`sum1` captured the old x** — `sum1 = x + y` was evaluated when `x` was 20, so `sum1 = 30`. The later `x = 100` doesn't change `sum1`
4. **The environment is immutable** — `addBinding` creates a NEW environment, it doesn't modify the old one

---

## FILE 3: `evaluate.ml` — Now passes EmptyEnv

[Open evaluate.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/evaluate.ml)

```diff
-Printf.printf "\n\t = %d\n" (Expression.eval e1)
+Printf.printf "\n\t = %d\n" (Expression.eval e1 Env.EmptyEnv)
```

**The only change**: `eval` now needs an environment. We start with `EmptyEnv` because at the beginning of a program, no variables exist yet.

---

## FILE 4: `parser.mly` — Two new grammar rules

[Open parser.mly](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/parser.mly)

```diff
 expr :
+  | ID                               { Expression.Id($1) }
   | expr ADD expr                    { Expression.Add($1, $3) }
   | expr SUBTRACT expr               { Expression.Subtract($1, $3) }
   | INTEGER                          { Expression.Const $1 }
   | IF bool_expr THEN expr ELSE expr { Expression.IfExpr($2, $4, $6) }
+  | LET ID EQ expr IN expr           { Expression.LetExpr($2, $4, $6) }
```

**`ID`** — When the parser sees a bare identifier like `x`, it builds `Id("x")`.
**`LET ID EQ expr IN expr`** — When it sees `let x = ... in ...`, it builds `LetExpr("x", e1, e2)`. `$2` is the variable name, `$4` is the bound expression, `$6` is the body.

---

## FILE 5: `lexer.mll` — Three new tokens

[Open lexer.mll](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/lexer.mll)

```diff
+  | '='    { Parser.EQ }
+  | "let"  { Parser.LET }
+  | "in"   { Parser.IN }
```

Again, `"let"` and `"in"` must appear BEFORE the `id` rule so they're recognised as keywords, not identifiers.

---

## The Formal Semantics (let-semantics.txt)

[Open let-semantics.txt](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/let/let-semantics.txt)

```
Let
===
   env[var = val] |- e --> v
   env |- e1 --> val
--------------------------------------------
env |- let var = e1 in e --> v
```

**How to read this**: The stuff above the line are **premises** (things that must be true). The stuff below is the **conclusion**.

Reading bottom-up:
- "To evaluate `let var = e1 in e` in environment `env`..."
- "First evaluate `e1` in `env` to get `val`" (second premise)
- "Then evaluate `e` in `env` extended with `var = val`" (first premise)
- "The result is `v`"

This is exactly what the code does!

---

## What's Next? Why `let2/` exists

`let/` works, but it has a structural limitation: `eval` returns `int`. This means the environment can only store `int` values. When we add functions (`proc/`), we'll need the environment to store **closures** (function values), not just integers.

`let2/` is a **refactoring step** — same language, same features, but `eval` returns `Expression.expr` instead of `int`, and the environment stores `Expression.expr` values. This prepares the code for closures.
