# Semantics — File-by-File Explanation

## What is Semantics?

You've written `3 + 4 * 2` in a file. The lexer turned it into tokens. The parser built a tree. Now what? **Someone has to actually compute the answer.** That's what semantics does — it gives **meaning** to the tree structure.

Each subfolder in `semantics/` is a **complete, working interpreter** for a tiny programming language. They build on each other — each one adds ONE new feature:

```
const/     →  if/      →  if_bool/   →  let/     →  let2/    →  proc/      →  letrec/
(numbers)    (if-else)   (booleans)    (variables)  (refactor)  (functions)   (recursion)
```

We start with the absolute simplest: `const/` — a language that only has **integers and arithmetic**.

---
---

# FOLDER 1: `semantics/const/` — The Simplest Interpreter

## What can this language do?

Only three things:
- Write an integer: `42`
- Add: `3 + 4`
- Subtract: `10 - 3`

That's it. No variables, no if-else, no functions. Just a calculator.

## Why start here?

Because it isolates the **core idea of an interpreter** with zero distractions. Once you understand how `const/` works, every subsequent folder just adds one more case to the same pattern.

---

## The files and their roles:

```
const/
├── expression.ml    ← THE CORE: defines what expressions look like + how to evaluate them
├── expression.mli   ← Interface: what expression.ml exposes to other modules
├── parser.mly       ← Grammar: how tokens become an expression tree (AST)
├── lexer.mll        ← Tokeniser: how raw text becomes tokens
├── evaluate.ml      ← Entry point: wires everything together
├── Makefile          ← Build instructions
└── examples/        ← Test inputs
    ├── 1.txt          "123"
    ├── 2.txt          "123 + 1"
    └── 3.txt          "1 +2 - 3 + 4 + 5 + 6 - 9 + 34 + 9 + 444 + 4 - 10 - 123"
```

### The data flow (what happens when you run `./evaluate examples/2.txt`):

```
"123 + 1"  →  lexer  →  [INTEGER(123); ADD; INTEGER(1); EOF]
                            ↓
                         parser  →  Add(Const(123), Const(1))
                                       ↓
                                    eval  →  124
                                               ↓
                                            print "= 124"
```

I'll explain each file in the order that makes the most sense conceptually: **expression.ml first** (the heart), then parser/lexer (the plumbing), then evaluate.ml (the glue).

---

## FILE 1: `expression.ml` — The Heart of the Interpreter

[Open expression.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/const/expression.ml)

### Why does this file exist?

Every interpreter needs to answer two questions:
1. **What does an expression look like?** (the AST type)
2. **What does an expression mean?** (the eval function)

This file answers both.

### Part 1: The AST type (lines 6-9)

```ocaml
type expr =
  | Const of int               (* an integer literal, e.g. 42 *)
  | Add   of expr * expr       (* e1 + e2 *)
  | Subtract of expr * expr    (* e1 - e2 *)
```

**Why a type?** Because we need a way to represent `3 + 4` as a **data structure** that the evaluator can walk through. A string `"3 + 4"` is just characters — useless for computation. But `Add(Const(3), Const(4))` is a tree that the `eval` function can pattern-match on.

**Why is it recursive?** Because expressions nest. In `(3 + 4) - 1`, the left side of `Subtract` is itself an `Add`:

```
Subtract(
  Add(Const(3), Const(4)),    ← left side is another expression
  Const(1)                     ← right side is a simple number
)
```

**What each constructor means:**

| Constructor | Represents | Example code | AST |
|---|---|---|---|
| `Const(n)` | A plain number | `42` | `Const(42)` |
| `Add(e1, e2)` | Addition | `3 + 4` | `Add(Const(3), Const(4))` |
| `Subtract(e1, e2)` | Subtraction | `10 - 3` | `Subtract(Const(10), Const(3))` |

### Part 2: The eval function (lines 14-22)

```ocaml
let rec eval e =
  match e with
  | Const(c) -> c
  | Add(e1, e2) ->
      let i1 = (eval e1) and i2 = (eval e2) in
      i1 + i2
  | Subtract(e1, e2) ->
      let i1 = (eval e1) and i2 = (eval e2) in
      i1 - i2
```

**Why `let rec`?** Because `eval` calls itself. To evaluate `Add(e1, e2)`, you first need to evaluate `e1` and `e2` — which are themselves expressions. This is **structural recursion**: the function follows the recursive structure of the type.

**The thought process for each case:**

| Pattern | Thought process | Result |
|---|---|---|
| `Const(c)` | "A number is already a value. Nothing to compute." | Return `c` directly |
| `Add(e1, e2)` | "I need to compute both sides first, THEN add." | Recursively eval both, add results |
| `Subtract(e1, e2)` | Same but subtract | Recursively eval both, subtract results |

### Trace: `eval (Add(Const(3), Subtract(Const(10), Const(3))))`

This represents `3 + (10 - 3)`:

```
eval Add(Const(3), Subtract(Const(10), Const(3)))
  → need eval Const(3)  AND  eval Subtract(Const(10), Const(3))

  eval Const(3) → 3

  eval Subtract(Const(10), Const(3))
    → need eval Const(10) AND eval Const(3)
    → eval Const(10) → 10
    → eval Const(3)  → 3
    → 10 - 3 → 7

  → 3 + 7 → 10
```

> [!IMPORTANT]
> **Key insight**: `eval` has NO environment, NO variables, NO state. It's a pure function: expression in, integer out. This is the simplest possible evaluator. Starting from the next folder (`if/`), things will get more complex — but the pattern **always** stays the same: pattern match on the AST node, recursively evaluate sub-expressions, combine results.

---

## FILE 2: `expression.mli` — The Interface

[Open expression.mli](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/const/expression.mli)

```ocaml
type expr =
  | Const of int
  | Add   of expr * expr
  | Subtract   of expr * expr

val eval : expr -> int
```

**Why does this exist?** It tells other modules (like `parser.mly` and `evaluate.ml`): "Here's what `Expression` provides — a type called `expr` and a function called `eval`. That's all you need to know." The implementation details in `expression.ml` are hidden.

The parser uses `Expression.Add($1, $3)` to build AST nodes — it knows about the type from this interface.

---

## FILE 3: `parser.mly` — Grammar Rules

[Open parser.mly](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/const/parser.mly)

### Why does this file exist?

The lexer produces tokens like `[INTEGER(3); ADD; INTEGER(4)]`. But the evaluator needs a **tree** like `Add(Const(3), Const(4))`. Someone needs to convert the flat token list into a tree. That's what the parser does, and **this file defines the rules**.

### The grammar (lines 19-23):

```ocaml
expr :
    expr ADD expr      { Expression.Add($1, $3) }
  | expr SUBTRACT expr { Expression.Subtract($1, $3) }
  | INTEGER            { Expression.Const $1 }
;
```

**How to read each rule:**

| Rule | Meaning | Action (builds AST node) |
|---|---|---|
| `expr ADD expr` | "An expression can be: expression + expression" | Build `Add(left, right)` |
| `expr SUBTRACT expr` | "An expression can be: expression - expression" | Build `Subtract(left, right)` |
| `INTEGER` | "An expression can be: just a number" | Build `Const(n)` |

`$1` = first thing, `$3` = third thing (skipping the operator in the middle).

### The precedence line (line 15):

```ocaml
%left ADD SUBTRACT
```

**What this means**: `+` and `-` have equal precedence and are **left-associative**. So `1 + 2 - 3` is parsed as `(1 + 2) - 3`, not `1 + (2 - 3)`.

### The token declarations (lines 7-10):

```ocaml
%token NEWLINE WS COMMA EOF LPAREN RPAREN COLON
%token ADD SUBTRACT
%token <int> INTEGER
%token <string> ID
```

**Why `<int>` on INTEGER?** Because `INTEGER` carries a value (the actual number). `ADD` doesn't carry anything — it's just the `+` symbol. The `<int>` tells `ocamlyacc` that when the lexer sends an `INTEGER` token, it comes with an `int` payload.

---

## FILE 4: `lexer.mll` — Token Rules

[Open lexer.mll](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/const/lexer.mll)

### Why does this file exist?

The input is a string like `"123 + 1"`. The parser doesn't understand strings — it needs **tokens**. The lexer scans the string and produces tokens.

### The rules (lines 14-24):

```ocaml
rule scan = parse
  | [' ' '\t' '\n']+  { scan lexbuf }                          (* skip whitespace *)
  | '+'               { Parser.ADD }                           (* produce ADD token *)
  | '-'               { Parser.SUBTRACT }                      (* produce SUBTRACT *)
  | integer as s      { Parser.INTEGER((int_of_string s)) }   (* produce INTEGER(n) *)
  | eof               { Parser.EOF }                           (* end of input *)
```

**The thought process**: The lexer tries each rule top to bottom. For each chunk of input, it finds the first matching pattern and runs the action in `{ }`. Whitespace is consumed silently (the action just calls `scan lexbuf` again to get the next token).

### Trace: lexing `"3 + 4"`

```
Position 0: '3' matches integer → produce INTEGER(3)
Position 1: ' ' matches whitespace → skip, call scan again
Position 2: '+' matches '+' → produce ADD
Position 3: ' ' matches whitespace → skip
Position 4: '4' matches integer → produce INTEGER(4)
Position 5: eof → produce EOF

Result: [INTEGER(3); ADD; INTEGER(4); EOF]
```

---

## FILE 5: `evaluate.ml` — The Entry Point (Glue Code)

[Open evaluate.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/semantics/const/evaluate.ml)

### Why does this file exist?

We have three pieces: lexer, parser, evaluator. Someone needs to **wire them together**. This file does that in 3 lines of actual logic:

```ocaml
let cin = if Array.length Sys.argv > 1
          then open_in Sys.argv.(1)    (* read from file *)
          else stdin                    (* or from keyboard *)
in
let lexbuf = Lexing.from_channel cin in
let e1 = Parser.expr Lexer.scan lexbuf in   (* lex + parse → AST *)
Printf.printf "\n\t = %d\n" (Expression.eval e1)   (* eval + print *)
```

### The critical line: `Parser.expr Lexer.scan lexbuf`

This is where all three phases happen:
1. `lexbuf` wraps the input channel into a buffer the lexer can read from
2. `Lexer.scan` is passed to the parser — the parser calls it whenever it needs the next token
3. `Parser.expr` runs the grammar rules, calling `Lexer.scan` as needed, building the AST
4. The result `e1` is a complete `Expression.expr` tree

Then `Expression.eval e1` walks the tree and computes the integer result.

---

## Full End-to-End Trace: `./evaluate examples/2.txt`

Input file `2.txt` contains: `123 + 1`

```
STAGE 1 — LEXER (lexer.mll)
  "123 + 1" → [INTEGER(123); ADD; INTEGER(1); EOF]

STAGE 2 — PARSER (parser.mly)
  Matches rule: expr ADD expr
  $1 = INTEGER(123) → Expression.Const(123)
  $3 = INTEGER(1)   → Expression.Const(1)
  Builds: Expression.Add(Const(123), Const(1))

STAGE 3 — EVALUATOR (expression.ml)
  eval Add(Const(123), Const(1))
    eval Const(123) → 123
    eval Const(1)   → 1
    123 + 1 → 124

OUTPUT: "= 124"
```

---

## What's Missing? (Preview of next folders)

| What you CAN'T do in `const/` | Which folder adds it | What changes in the code |
|---|---|---|
| `if 3 = 3 then 42 else 0` | `if/` | Add `IfExpr` to the AST type + one more case in `eval` |
| `true && not false` | `if_bool/` | Add `bool_expr` type + `bool_eval` function |
| `let x = 3 in x + 1` | `let/` | Add `Id`, `LetExpr` to AST + add **environment** parameter to `eval` |
| `fun x -> x + 1` | `proc/` | Add `FunDef`, `FunApp`, `Closure` + closure creation logic |
| `let rec fact = fun n -> ...` | `letrec/` | Add `RecClosure` + self-referencing environment trick |

> Each step adds **one case** to the pattern match in `eval`. The skeleton never changes.
