# Semantics Part 2: `if/` and `if_bool/` — Adding Conditionals

---

# FOLDER 2: `semantics/if/` — Adding If-Then-Else

## Why do we need this?

In `const/`, the language is a **straight-line calculator** — it always computes everything. There's no way to make a decision. But real programs need to **choose between alternatives**: "if the user is logged in, show the dashboard; otherwise, show the login page."

`if/` adds the simplest form of decision-making: `if true then 42 else 0`.

## What EXACTLY changed from `const/`?

Only **4 things** were added. Everything else is identical to `const/`:

| What changed | Where | The addition |
|---|---|---|
| 1. New AST node | `expression.ml` | `IfExpr of bool * expr * expr` |
| 2. New eval case | `expression.ml` | One new pattern match branch |
| 3. New tokens | `lexer.mll` | `if`, `then`, `else`, `true`, `false` |
| 4. New grammar rule | `parser.mly` | `IF BOOLEAN THEN expr ELSE expr` |

That's it. The **structure** of the interpreter doesn't change. We're just adding one more branch to the pattern match.

---

## FILE 1: `expression.ml` — One new AST node + one new eval case

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if/expression.ml)

### The AST type (what changed from const/):

```diff
 type expr =
   | Const of int
   | Add   of expr * expr
   | Subtract of expr * expr
+  | IfExpr of bool * expr * expr    ← NEW
```

**Notice something important**: the condition is `bool`, NOT `expr`. It's a **literal** `true` or `false` hardcoded into the syntax. You can write `if true then ...` or `if false then ...`, but you CANNOT write `if (3 = 3) then ...` — there's no way to compute a boolean from expressions yet. That limitation is what `if_bool/` fixes.

### The eval function (what changed from const/):

```diff
 let rec eval e =
   match e with
   | Const(c) -> c
   | Add(e1, e2) -> ...
   | Subtract(e1, e2) -> ...
+  | IfExpr(b, e1, e2) -> if b = true then (eval e1) else (eval e2)
```

**The thought process**: "I have a condition `b` and two branches. If the condition is true, evaluate the first branch. Otherwise, evaluate the second branch. Only ONE branch gets evaluated — the other is ignored."

### Trace: `eval (IfExpr(true, Add(Const(2), Const(4)), Const(99)))`

This represents `if true then 2 + 4 else 99`:

```
eval IfExpr(true, Add(Const(2), Const(4)), Const(99))
  b = true → evaluate the THEN branch
  eval Add(Const(2), Const(4))
    eval Const(2) → 2
    eval Const(4) → 4
    2 + 4 → 6

Result: 6
(The else branch Const(99) was never evaluated!)
```

### Trace: `eval (IfExpr(false, Const(42), Subtract(Const(10), Const(3))))`

This represents `if false then 42 else 10 - 3`:

```
eval IfExpr(false, Const(42), Subtract(Const(10), Const(3)))
  b = false → evaluate the ELSE branch
  eval Subtract(Const(10), Const(3))
    10 - 3 → 7

Result: 7
(The then branch Const(42) was never evaluated!)
```

> [!IMPORTANT]
> **Key insight**: Only one branch is evaluated. This is **not** like `Add(e1, e2)` where both sides are always evaluated. In `if-then-else`, the un-chosen branch is completely skipped. This matters later when branches might have side effects or infinite loops.

---

## FILE 2: `parser.mly` — New grammar rule

[Open parser.mly](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if/parser.mly)

```diff
 expr :
     expr ADD expr      { Expression.Add($1, $3) }
   | expr SUBTRACT expr { Expression.Subtract($1, $3) }
   | INTEGER            { Expression.Const $1 }
+  | if_expr            { $1 }                          ← NEW
 ;

+if_expr : IF BOOLEAN THEN expr ELSE expr
+          { Expression.IfExpr($2, $4, $6) }            ← NEW
```

**Why a separate `if_expr` rule?** To keep the grammar clean. `if_expr` is its own production that gets used as one of the alternatives for `expr`. The `$2` is `BOOLEAN` (the condition), `$4` is the then-expression, `$6` is the else-expression.

### How the parser handles `"if true then 2 + 4 else 1 + 2"`:

```
Tokens: [IF; BOOLEAN(true); THEN; INTEGER(2); ADD; INTEGER(4); ELSE; INTEGER(1); ADD; INTEGER(2)]

Parser matches: IF BOOLEAN THEN expr ELSE expr
  $2 = true
  $4 = expr ADD expr → Add(Const(2), Const(4))
  $6 = expr ADD expr → Add(Const(1), Const(2))

Builds: IfExpr(true, Add(Const(2), Const(4)), Add(Const(1), Const(2)))
```

---

## FILE 3: `lexer.mll` — New keyword tokens

[Open lexer.mll](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if/lexer.mll)

Five new rules added to const's lexer:

```diff
   | integer as s { Parser.INTEGER((int_of_string s)) }
+  | "if"         { Parser.IF }
+  | "then"       { Parser.THEN }
+  | "else"       { Parser.ELSE }
+  | "true"       { Parser.BOOLEAN(true) }
+  | "false"      { Parser.BOOLEAN(false) }
   | id as s      { Parser.ID(s) }
```

**Why must `"if"` come before `id`?** Because `"if"` also matches the `id` pattern (letters followed by letters). `ocamllex` tries rules top-to-bottom and picks the **first** match. If `id` came first, `"if"` would be tokenised as `ID("if")` instead of `IF`.

---

## FILE 4: `evaluate.ml` — Identical to const/

[Open evaluate.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if/evaluate.ml)

No changes from `const/evaluate.ml`. The glue code is exactly the same — it doesn't care what features the language has. It just calls `Parser.expr Lexer.scan lexbuf` and then `Expression.eval`.

---

## The Problem with `if/`: Why do we need `if_bool/`?

In `if/`, the condition is a **literal boolean** — you type `true` or `false` directly:

```
if true then 42 else 0     ← this works
if false then 42 else 0    ← this works
if (3 = 3) then 42 else 0  ← THIS DOESN'T WORK! No way to compute a boolean.
```

This is useless in practice. You want conditions that are **computed**, not hardcoded. That's what `if_bool/` adds.

---
---

# FOLDER 3: `semantics/if_bool/` — Compound Boolean Expressions

## Why do we need this?

`if/` proved that we can branch. But the condition was a literal `true`/`false`, which is pointless — you always know which branch runs. We need **boolean expressions** that can be computed at runtime: `true and not false`, `(true or false) and true`, etc.

## What EXACTLY changed from `if/`?

| What changed | The addition |
|---|---|
| New type `bool_expr` | `Boolean`, `And`, `Or`, `Not` — a separate AST for booleans |
| New function `bool_eval` | Evaluates boolean expressions to OCaml `bool` |
| `IfExpr` condition type | Changed from `bool` to `bool_expr` |
| New tokens | `and`, `or`, `not` keywords |
| New grammar rules | `bool_expr` production with `AND`, `OR`, `NOT`, parentheses |

---

## FILE 1: `expression.ml` — Two separate type systems

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if_bool/expression.ml)

### The big design decision: TWO types instead of one

```ocaml
(* Boolean expression AST — separate from integer expressions *)
type bool_expr =
  | Boolean of bool                       (* literal true or false *)
  | And of bool_expr * bool_expr          (* b1 and b2 *)
  | Or of bool_expr * bool_expr           (* b1 or b2 *)
  | Not of bool_expr                      (* not b *)

(* Integer expression AST *)
type expr =
  | Const of int
  | Add   of expr * expr
  | Subtract of expr * expr
  | IfExpr of bool_expr * expr * expr     (* ← changed! was 'bool', now 'bool_expr' *)
```

**Why two separate types?** Because booleans and integers are **different kinds of values**. An `And` takes two booleans and returns a boolean. An `Add` takes two integers and returns an integer. They don't mix — you can't write `true + 3` or `5 and 6`. Having two types makes the compiler **enforce** this separation.

**The change to `IfExpr`**: The condition was `bool` (a plain OCaml boolean). Now it's `bool_expr` (our custom AST type). This means the condition can be a compound expression like `And(Boolean(true), Not(Boolean(false)))`.

### Two separate eval functions:

```ocaml
(* Evaluates boolean expressions to OCaml bool *)
let rec bool_eval e =
  match e with
  | Boolean(b)    -> b
  | And(b1, b2)   -> (bool_eval b1) && (bool_eval b2)
  | Or(b1, b2)    -> (bool_eval b1) || (bool_eval b2)
  | Not(b)        -> not (bool_eval b)

(* Evaluates integer expressions to OCaml int *)
let rec eval e =
  match e with
  | Const(c) -> c
  | Add(e1, e2) -> ...
  | Subtract(e1, e2) -> ...
  | IfExpr(b, e1, e2) -> if (bool_eval b) = true then (eval e1) else (eval e2)
                              ↑ calls bool_eval, not eval!
```

**The thought process**: `eval` handles integers. But the condition of `if-then-else` is a boolean. So `eval` calls `bool_eval` for the condition, gets back `true` or `false`, then picks the right integer branch.

### Trace: `if (true or false) and (not false) then 100 else 200`

AST:
```
IfExpr(
  And(
    Or(Boolean(true), Boolean(false)),
    Not(Boolean(false))
  ),
  Const(100),
  Const(200)
)
```

Evaluation:
```
eval IfExpr(And(...), Const(100), Const(200))
  → bool_eval And(Or(...), Not(...))

    bool_eval Or(Boolean(true), Boolean(false))
      bool_eval Boolean(true)  → true
      bool_eval Boolean(false) → false
      true || false → true

    bool_eval Not(Boolean(false))
      bool_eval Boolean(false) → false
      not false → true

    true && true → true

  → condition is true → eval Const(100) → 100

Result: 100
```

---

## FILE 2: `parser.mly` — New `bool_expr` grammar

[Open parser.mly](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if_bool/parser.mly)

```diff
-if_expr : IF BOOLEAN THEN expr ELSE expr
+if_expr : IF bool_expr THEN expr ELSE expr
              ↑ was BOOLEAN (literal), now bool_expr (compound)

+bool_expr:
+    BOOLEAN                       { Expression.Boolean $1 }
+  | bool_expr AND bool_expr       { Expression.And($1, $3) }
+  | bool_expr OR bool_expr        { Expression.Or($1, $3) }
+  | NOT bool_expr                 { Expression.Not($2) }
+  | LPAREN bool_expr RPAREN       { $2 }
```

**Precedence rules added:**
```ocaml
%left AND OR      (* and/or are left-associative *)
%right NOT        (* not binds tighter and is right-associative *)
```

So `not true and false` is parsed as `(not true) and false`, not `not (true and false)`.

---

## FILE 3: `lexer.mll` — Three new keywords

[Open lexer.mll](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/if_bool/lexer.mll)

```diff
+  | "and"   { Parser.AND }
+  | "or"    { Parser.OR }
+  | "not"   { Parser.NOT }
```

---

## What's Still Missing?

Even with `if_bool/`, you CANNOT write:

```
if 3 = 3 then 42 else 0          ← no equality operator on integers
if x then 42 else 0              ← no variables!
let x = 3 in if x = 3 then ...   ← no let bindings!
```

The condition is still purely boolean — you can't **compare integers** or use **variables**. Those come in `let/` (next folder), where we introduce the **environment** — the single biggest conceptual leap in the entire codebase.

> [!IMPORTANT]
> **The pattern so far**: Each folder adds ONE feature by:
> 1. Adding a constructor to the `expr` type (or a new type)
> 2. Adding one case to `eval`
> 3. Adding tokens to the lexer and rules to the parser
>
> The interpreter's **skeleton** never changes. This is the power of the AST + pattern matching design.
