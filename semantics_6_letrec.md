# Semantics Part 6: `letrec/` — Recursion (The Final Piece)

---

# FOLDER 7: `semantics/letrec/` — Making Functions Call Themselves

## Why do we need this?

In `proc/`, we can define functions and call them. But we **cannot** write:

```
let fact = fun n ->
  if n = 1 then 1
  else fact (n - 1) * n       ← fact calls ITSELF
in
fact 5
```

**Why it fails in `proc/`:**

```
Step 1: eval FunDef("n", body) in env=[]
        → Closure("n", body, [])       ← captures EMPTY env!

Step 2: addBinding "fact" (Closure("n", body, [])) to env
        → env = [fact = Closure("n", body, [])]

Step 3: eval FunApp(Id"fact", IntConst 5) in env=[fact=Closure(...)]
        → eval Id"fact" → Closure("n", body, [])    ← closure's env is EMPTY
        → extend closure's env: env' = [n=5]
        → eval body in env'=[n=5]

Step 4: body says: fact (n - 1) * n
        → eval Id"fact" in env=[n=5]
        → apply "fact" [n=5]
        → NOT FOUND! 💥  ← fact is NOT in the closure's captured env!
```

**The chicken-and-egg problem**: When `fun n -> ...` is evaluated (Step 1), `fact` hasn't been bound yet (that happens in Step 2). So the closure captures an env without `fact`. Later, when the body tries to call `fact`, it can't find it.

---

## The Solution: `RecClosure` and the Re-injection Trick

Instead of solving this at **definition time** (impossible — `fact` doesn't exist yet), we solve it at **lookup time**. When someone looks up a recursive function in the environment, we **inject the function into its own closure's environment** right before returning it.

### The three changes:

| What's new | Where | Purpose |
|---|---|---|
| `RecFunDef of string * expr` | expression.ml | Syntax: marks a function as recursive |
| `RecClosure of string * expr * env` | expression.ml | Like Closure, but tagged "I'm recursive" |
| Re-injection in `apply` | expression.ml L113-127 | When RecClosure is looked up, inject it into its own env |

---

## FILE 1: `expression.ml` — RecClosure + The apply Trick

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/letrec/expression.ml)

### New AST nodes (lines 31-35):

```ocaml
| RecFunDef  of string * expr          (* syntax: like FunDef but for recursive fns *)
| RecClosure of string * expr * env    (* runtime: like Closure but tagged "recursive" *)
```

### The critical function: `apply` (lines 113-127)

This is where the **entire recursion trick** lives:

```ocaml
let rec apply x env =
  match env with
    EmptyEnv -> raise Not_found
  | NonEmptyEnv((vname, value), env') ->
    if x = vname then
    (
      match value with
        | RecClosure(_, _, _) ->
            (* THE TRICK: re-inject f into its own environment *)
            let (par, body, env'') = getClosureValue(value) in
            let env''' = (addBinding vname (RecClosure(par, body, env'')) env'') in
              Closure(par, body, env''')
        | _ -> value
    )
    else (apply x env')
```

### Understanding the trick step by step:

When `apply "fact" env` finds that `fact` is a `RecClosure(par, body, env'')`:

```
1. Unpack:  par = "n",  body = if n=1 then 1 else fact(n-1)*n,  env'' = [...]

2. Re-inject: env''' = addBinding "fact" (RecClosure("n", body, env'')) env''
              ↑ Add "fact" → RecClosure INTO the closure's own captured env

3. Return: Closure("n", body, env''')
           ↑ Return a regular Closure with the enriched env
```

**Result**: The returned Closure now has `fact` available in its environment. So when the body calls `fact(n-1)`, it will find `fact` in `env'''`, which will AGAIN trigger the RecClosure re-injection, and so on forever — enabling unlimited recursion.

> [!IMPORTANT]
> **The trick is lazy**: We don't try to build an infinite environment. We only inject `fact` when someone actually looks it up. Each recursive call triggers a fresh re-injection. It's like a function that says "when you need me, I'll make sure I'm available for the next call too."

---

## FILE 2: `interpreter.ml` — Almost identical to proc/

[Open interpreter.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/letrec/interpreter.ml)

Only **two lines** differ from `proc/interpreter.ml`:

```ocaml
(* RecFunDef: same as FunDef but creates a RecClosure *)
| Expression.RecFunDef(par, body) -> Expression.RecClosure(par, body, env)

(* RecClosure is a value — return as-is *)
| Expression.RecClosure(_, _, _) -> e
```

That's it. The FunApp case is **unchanged** — it doesn't know or care whether the closure is recursive. The magic is entirely in `apply`.

---

## Detailed Trace: `fact 4` (examples/14.txt)

```
let rec fact =
  fun n ->
    if n = 1 then 1
    else ((fact (n - 1)) * n)
in
(fact 4)
```

```
═══ Step 1: eval Let("fact", RecFunDef("n", body), FunApp(Id"fact", IntConst 4))
  in env=[]

  eval RecFunDef("n", body) in env=[]
    → RecClosure("n", body, [])          ← tagged as recursive

  env = [fact = RecClosure("n", body, [])]

═══ Step 2: eval FunApp(Id"fact", IntConst 4) in env=[fact=RecClosure(...)]

  eval Id"fact" → apply "fact" env
    ← fact is a RecClosure! Trigger the trick:
    par="n", body=..., env''=[]
    env''' = addBinding "fact" RecClosure("n",body,[]) []
           = [fact = RecClosure("n", body, [])]
    Return: Closure("n", body, [fact = RecClosure("n", body, [])])
                                 ↑ fact is now in the closure's env!

  Unpack Closure: par="n", body=..., env'=[fact=RecClosure(...)]
  eval IntConst(4) → IntConst(4)
  env'' = [n=4, fact=RecClosure("n", body, [])]

  eval body in env=[n=4, fact=RecClosure(...)]
    eval If(Equals(Id"n", IntConst 1), ...)
      n=4, 4≠1 → else branch
      eval Multiply(FunApp(Id"fact", Sub(Id"n", IntConst 1)), Id"n")

═══ Step 3: eval FunApp(Id"fact", Sub(Id"n", IntConst 1))
  in env=[n=4, fact=RecClosure(...)]

  eval Id"fact" → apply "fact" env
    ← RecClosure again! Re-inject:
    Return: Closure("n", body, [fact=RecClosure(...)])
                                 ↑ fact available again!

  eval Sub(Id"n", IntConst 1) → 4-1 = IntConst(3)
  env = [n=3, fact=RecClosure(...)]
  eval body → n=3, 3≠1 → else → fact(2) * 3

═══ Step 4: fact(2) → n=2, 2≠1 → fact(1) * 2

═══ Step 5: fact(1) → n=1, 1=1 → IntConst(1)   ← BASE CASE!

═══ Unwinding:
  fact(1) = 1
  fact(2) = fact(1) * 2 = 1 * 2 = 2
  fact(3) = fact(2) * 3 = 2 * 3 = 6
  fact(4) = fact(3) * 4 = 6 * 4 = 24

Result: IntConst(24) ✅
```

### What happened at each recursive call:

Every time `eval Id"fact"` runs, `apply` detects the `RecClosure`, re-injects `fact` into the closure's env, and returns a regular `Closure`. This `Closure` has `fact` available, so the next call will work too. It's an on-demand chain.

---

## The Complete Evolution Summary

| Folder | Feature Added | Key Code Change | New Concept |
|--------|--------------|-----------------|-------------|
| `const/` | Arithmetic | `eval : expr -> int` | Pattern matching on AST |
| `if/` | If-then-else | `IfExpr(bool, expr, expr)` | Branch evaluation |
| `if_bool/` | Boolean expressions | `bool_expr` type + `bool_eval` | Two-type system |
| `let/` | Variables | `eval : expr -> env -> int` | **Environment** (name→value mapping) |
| `let2/` | (refactor) | `eval` returns `expr`, not `int` | Unified value type |
| `proc/` | Functions | `Closure(par, body, env)` | **Closures** (lexical scoping) |
| `letrec/` | Recursion | `RecClosure` + `apply` re-injection | **Self-referencing environment** |

### The design pattern that NEVER changed:

```ocaml
let rec eval e env =
  match e with
  | SomeNode(args...) ->
      (* evaluate sub-expressions *)
      (* combine results *)
      (* return a value *)
```

Every folder just added **one more case** to this pattern match. The skeleton is the same from `const/` to `letrec/`.

---

## 🎓 You Now Understand a Complete Interpreter

From raw text to computed result:

```
"let rec fact = fun n -> if n=1 then 1 else fact(n-1)*n in fact 5"

  ↓ LEXER (lexer.mll)
[LET; REC; ID"fact"; EQ; FUN; ID"n"; ARROW; IF; ID"n"; EQ; INT 1; ...]

  ↓ PARSER (parser.mly)
Let("fact", RecFunDef("n", If(Equals(Id"n",IntConst 1), IntConst 1,
  Multiply(FunApp(Id"fact", Sub(Id"n",IntConst 1)), Id"n"))), FunApp(Id"fact", IntConst 5))

  ↓ INTERPRETER (interpreter.ml + expression.ml)
IntConst(120)

  ↓ PRINTER (evaluate.ml)
"= 120"
```
