# Semantics Part 5: `proc/` — Closures and First-Class Functions

---

# FOLDER 6: `semantics/proc/` — The Second Biggest Conceptual Leap

## Why do we need this?

In `let2/`, you can compute values and bind them to names. But you can't **abstract over computation itself**. You can't say "here's a recipe for adding 5 to something" and reuse it:

```
let add_five = fun x -> x + 5 in
add_five 10           ← gives 15
add_five 20           ← gives 25
```

Functions let you **package up computation** and reuse it with different inputs. And "first-class functions" means functions are **values** — just like integers. You can store them in variables, pass them as arguments, return them from other functions.

But functions create a deep problem: **what happens to variables from the surrounding scope?**

```
let y = 10 in
let f = fun x -> x + y in    ← f uses y from the outer scope!
let y = 999 in                ← y is reassigned
f 5                           ← should this give 15 or 1004?
```

The answer is **15** — `f` remembers `y = 10` from when it was **defined**, not from when it's **called**. This is called **lexical scoping**, and the mechanism that makes it work is the **closure**.

---

## What changed from `let2/`?

| What's new | Why |
|---|---|
| `FunDef of string * expr` | Syntax for writing a function: `fun x -> body` |
| `FunApp of expr * expr` | Syntax for calling a function: `f 5` |
| `Closure of string * expr * env` | Runtime value: a function + its captured environment |
| `env` type moved into `expression.ml` | Because `Closure` contains `env` and `env` contains `expr` (mutual recursion) |

---

## The Core Idea: FunDef vs. Closure

This is the most important distinction in the entire codebase:

| | `FunDef("x", body)` | `Closure("x", body, env)` |
|---|---|---|
| **What is it?** | The code you **write** | The value **created at runtime** |
| **When does it exist?** | In the AST (after parsing) | After `eval` evaluates a `FunDef` |
| **Contains environment?** | ❌ No | ✅ Yes — a snapshot of the env at definition time |
| **Analogy** | A recipe written on paper | A recipe PLUS all the ingredients already gathered |

**`FunDef`** is what the parser produces from `fun x -> x + y`. It's pure syntax — it doesn't know what `y` is.

**`Closure`** is what `eval` produces when it evaluates that `FunDef`. It bundles the function with a **snapshot of the current environment**, so later, when the function is called, it knows `y = 10`.

---

## FILE 1: `expression.ml` — Three new AST nodes + environment moved in

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/proc/expression.ml)

### New AST nodes:

```diff
 type expr =
   | Id | IntConst | Add | Sub | If | Let | BoolConst | Not | Or | And | Equals
+  | Closure of string * expr * env    (* runtime value: param + body + captured env *)
+  | FunDef  of string * expr          (* syntax: fun param -> body *)
+  | FunApp  of expr * expr            (* syntax: function argument *)
```

### Why is `env` now inside `expression.ml`?

```ocaml
type expr =
  ...
  | Closure of string * expr * env      ← expr contains env

and env =                                ← env contains expr
    EmptyEnv
  | NonEmptyEnv of (string * expr) * env
```

`Closure` contains `env`, and `env` contains `expr`. They reference each other — **mutual recursion on types**, just like `tree` and `forest` in `la/fsm/tree.ml`! This is why they must be defined together with `and`.

In `let2/`, `env` was in its own separate module. Now it HAS to be in the same file as `expr` because of the circular dependency.

---

## FILE 2: `interpreter.ml` — Two new eval cases

[Open interpreter.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/proc/interpreter.ml)

### Case 1: Evaluating `FunDef` → creates a `Closure`

```ocaml
| Expression.FunDef(par, body) -> Expression.Closure(par, body, env)
```

**The thought process**: "Someone wrote `fun x -> x + y`. I'm evaluating this right now, in an environment where `y = 10`. I create a Closure that bundles the parameter name (`x`), the body (`x + y`), and a **snapshot** of the current environment (`{y=10}`). Later, when this function is called, it will use THIS environment, not whatever environment exists at call time."

**This single line is the entire closure mechanism.** The environment is captured at definition time.

### Case 2: Evaluating `FunApp` → calls a function

```ocaml
| Expression.FunApp(f, arg) ->
    let e' = (eval f env) in                              (* Step 1: eval f → get Closure *)
    let (par, body, env') = (getClosureValue e')          (* Step 2: unpack the closure *)
    and arg' = (eval arg env) in                          (* Step 3: eval the argument *)
    let env'' = (Expression.addBinding par arg' env') in  (* Step 4: extend CLOSURE's env *)
    (eval body env'')                                     (* Step 5: eval body in new env *)
```

**The 5-step recipe:**

```
Given:  f arg     (e.g., "add_five 10")

Step 1: Evaluate f → get Closure(par, body, env')
        "What is add_five? It's Closure("x", x+y, {y=10})"

Step 2: Unpack → par="x", body="x+y", env'={y=10}

Step 3: Evaluate arg → arg'
        "What is 10? It's IntConst(10)"

Step 4: Extend the CLOSURE's env: env'' = {x=10, y=10}
        NOT the caller's env!

Step 5: Evaluate body in env''
        eval (x + y) in {x=10, y=10} → 10 + 10 → 20
```

> [!IMPORTANT]
> **Step 4 is critical**: We extend the **closure's captured environment** (`env'`), NOT the caller's current environment (`env`). This is what makes lexical scoping work. The function body runs in the scope where the function was **defined**, augmented with the argument binding.

### Closure is a value — eval returns it as-is:

```ocaml
| Expression.Closure(_, _, _) -> e    (* already a value, like IntConst *)
```

Just like `IntConst(42)` is already a value, `Closure(...)` is already a value. You don't evaluate it further — you just return it.

---

## Detailed Trace: Currying (`examples/curry.txt`)

```
let make_adder = fun x -> fun y -> x + y in
let add_five = make_adder 5 in
add_five 10
```

**Expected**: `15`

```
═══ Step 1: eval LetExpr("make_adder", FunDef("x", FunDef("y", Add(Id"x",Id"y"))), ...)
  env = []

  eval FunDef("x", FunDef("y", Add(Id"x",Id"y")))  env=[]
    → Closure("x", FunDef("y", Add(Id"x",Id"y")), [])
                                                     ↑ captures empty env

  env = [make_adder = Closure("x", FunDef("y", x+y), [])]

═══ Step 2: eval LetExpr("add_five", FunApp(Id"make_adder", IntConst 5), ...)

  eval FunApp(Id"make_adder", IntConst 5)
    Step 1: eval Id"make_adder" → Closure("x", FunDef("y", x+y), [])
    Step 2: unpack → par="x", body=FunDef("y", x+y), env'=[]
    Step 3: eval IntConst(5) → IntConst(5)
    Step 4: env'' = [x=5]         ← extend closure's env with x=5
    Step 5: eval FunDef("y", x+y) in env=[x=5]
            → Closure("y", Add(Id"x",Id"y"), [x=5])
                                                ↑ captures env where x=5!

  env = [add_five = Closure("y", x+y, [x=5]), make_adder = ...]

═══ Step 3: eval FunApp(Id"add_five", IntConst 10)

    Step 1: eval Id"add_five" → Closure("y", x+y, [x=5])
    Step 2: unpack → par="y", body=x+y, env'=[x=5]
    Step 3: eval IntConst(10) → IntConst(10)
    Step 4: env'' = [y=10, x=5]    ← extend closure's env with y=10
    Step 5: eval Add(Id"x", Id"y") in env=[y=10, x=5]
            eval Id"x" → apply "x" [y=10, x=5] → 5
            eval Id"y" → apply "y" [y=10, x=5] → 10
            5 + 10 → IntConst(15)

Result: 15 ✅
```

### What just happened:

1. `make_adder` is a function that **returns another function**
2. `make_adder 5` creates a new closure where `x=5` is baked in
3. `add_five` is that new closure — it "remembers" `x=5`
4. `add_five 10` adds `y=10` and computes `x + y = 5 + 10 = 15`

This is **currying**: a two-argument function implemented as a function that returns a function.

---

## Lexical Scoping Proof: `examples/13.txt`

```
let x = 200 in
  let f = fun z -> z - x in      ← f captures x=200
    let x = 100 in                ← x is shadowed to 100
      let g = fun z -> z - x in  ← g captures x=100
      f 1 - g 1
```

**Expected**: `(1 - 200) - (1 - 100)` = `(-199) - (-99)` = `-100`

```
f = Closure("z", z-x, [x=200])       ← f captured x=200
g = Closure("z", z-x, [x=100, ...])  ← g captured x=100

f 1 → eval (z-x) in [z=1, x=200] → 1 - 200 = -199
g 1 → eval (z-x) in [z=1, x=100] → 1 - 100 = -99

f 1 - g 1 = -199 - (-99) = -100 ✅
```

**Key**: Even though `x` was reassigned to `100` before `f` was called, `f` still uses `x=200` from when it was **defined**. That's lexical scoping, powered by closures.

---

## The Formal Semantics (`proc-semantics.txt`)

[Open proc-semantics.txt](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/proc/proc-semantics.txt)

```
FunDef
======
env |- (fun vname -> body) --> closure(vname, body, env)

FunApp
======
env            |- e1 --> closure(vname, body, env')
env            |- e2 --> v2
env'[vname=v2] |- body --> v
---------------------------------------------------
env |- e1 e2 --> v
```

Reading the FunApp rule bottom-up:
- "To evaluate `e1 e2` in `env`..."
- "Evaluate `e1` → get a closure with its own `env'`"
- "Evaluate `e2` → get value `v2`"
- "Evaluate `body` in `env'` extended with `vname=v2`" (NOT in `env`!)
- "The result is `v`"

---

## What CAN'T proc/ do?

```
let fact = fun n ->
  if n = 1 then 1
  else fact (n - 1) * n       ← ERROR: fact is not in the closure's env!
in
fact 5
```

**Why it fails**: When `fun n -> ...` is evaluated, it captures the current environment. But `fact` hasn't been bound yet — the `let` binding is still being processed! So the closure's env doesn't contain `fact`, and the recursive call fails with `Not_found`.

**This is exactly what `letrec/` (the final folder) solves** — with `RecClosure`, a special closure that re-injects itself into its own environment when looked up.
