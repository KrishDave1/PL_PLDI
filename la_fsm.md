# LA Folder — File-by-File Explanation

## The Big Picture: Where Does Lexing Fit?

When a programming language runs your code, it does **three things in sequence**:

```
Phase 1: LEXING        Phase 2: PARSING        Phase 3: SEMANTICS
"let x = 3"     →     [LET, ID(x), EQ, 3]  →   Tree structure    →   Result: 3
(raw text)             (tokens)                  (AST)                 (value)
```

We are in **Phase 1: Lexing** — the job of turning raw text into tokens. A **lexer** is essentially a machine that reads characters one by one and decides "this group of characters is a number" or "this group is a keyword."

The theory behind lexers is **Finite State Machines (FSMs)**. That's why we start here.

---
---

# FILE 1: `la/fsm/fsm.ml`

[Open fsm.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/la/fsm/fsm.ml)

## Why are we studying FSMs?

Every lexer — whether hand-written or auto-generated — is an FSM under the hood. When `ocamllex` reads your regex rules and generates a lexer, it's building an FSM. Before we build a real lexer (in `la/manual/`), we need to understand **what an FSM is and how to code one in OCaml**.

This file answers: **"How do you turn a state-machine diagram into actual code?"**

The answer: **each state becomes a function, each transition becomes a function call.**

---

## Part A: `list_of_string` (lines 1-9)

### Why does this exist?

OCaml strings are opaque arrays — you can't pattern-match them like `match s with 'a' :: rest -> ...`. But FSMs work by consuming **one element at a time from a sequence**, which is exactly what pattern matching on lists does (`h :: t`). So we need a converter.

```ocaml
let list_of_string s =
  let rec iter i s =
    if i = (String.length s) then []
    else s.[i] :: (iter (i + 1)) s
  in
  iter 0 s
```

**Trace**: `list_of_string "hi"`
```
iter 0 "hi" → 'h' :: (iter 1 "hi")
                     → 'i' :: (iter 2 "hi")
                              → []       (2 = length "hi")
Result: ['h'; 'i']
```

**Connection to the bigger picture**: In the real lexer (`la/manual/`), we won't use lists — we'll use **lazy streams** instead (`mystream.ml`). But the idea is the same: process input one character at a time.

---

## Part B: `one_zero` (lines 20-34)

### Why this example?

This is the **simplest possible FSM** — just two states and a binary alphabet (`0` and `1`). The point isn't the specific language it recognises. The point is to see how **mutual recursion maps to state transitions**.

### The code:

```ocaml
let one_zero lst =
  let rec init l =
    match l with
      [] -> true
    | h :: t -> if h = 1 then (accept t) else false

  and accept l =
    match l with
      [] -> true
    | h :: t ->
      if h = 0 then (init t)
      else if h = 1  then (accept t)
      else false
  in
  init lst
```

### Thought process: How to read this as an FSM

**Step 1** — Identify the states. Each `let rec` / `and` function is a state:
- `init` = start state
- `accept` = second state

**Step 2** — Identify the transitions. Each function call to another state is a transition:

| In state | See input | Action | Code |
|----------|----------|--------|------|
| `init` | `1` | Go to `accept` | `if h = 1 then (accept t)` |
| `init` | `0` | Reject | `else false` |
| `init` | empty | Accept | `[] -> true` |
| `accept` | `1` | Stay in `accept` | `if h = 1 then (accept t)` |
| `accept` | `0` | Go back to `init` | `if h = 0 then (init t)` |
| `accept` | empty | Accept | `[] -> true` |

**Step 3** — Figure out what language this accepts.

Let's build intuition through traces:

**Trace 1: `[1; 0; 1; 0]` → true ✅**
```
init [1;0;1;0]  → h=1       → accept [0;1;0]
accept [0;1;0]  → h=0       → init [1;0]
init [1;0]      → h=1       → accept [0]
accept [0]      → h=0       → init []
init []         → empty     → true ✅
```
Pattern: `1,0,1,0` — each 0 is preceded by at least one 1.

**Trace 2: `[1; 1; 0; 0]` → false ❌**
```
init [1;1;0;0]  → h=1       → accept [1;0;0]
accept [1;0;0]  → h=1       → accept [0;0]
accept [0;0]    → h=0       → init [0]        ← back to init!
init [0]        → h=0, 0≠1  → false ❌        ← init demands a 1
```
**Why it rejects**: After the first `0`, we go back to `init`. `init` on line 24 says `if h = 1 then ... else false`. It will ONLY proceed on a `1`. The second `0` hits the `else false`.

**Trace 3: `[1; 1; 1]` → true ✅**
```
init [1;1;1] → accept [1;1] → accept [1] → accept [] → true ✅
```
Pure 1s — never leaves `accept`.

**Trace 4: `[0; 1]` → false ❌**
```
init [0;1] → h=0, 0≠1 → false ❌
```
`init` demands the very first element to be `1`.

### The actual language (the comment is wrong!)

> [!WARNING]
> The comment on line 12 claims this FSM accepts "all 1s before all 0s" and says `[1;1;0;0] -> true`. **This is incorrect.** As we traced above, `[1;1;0;0]` returns `false`.
>
> The actual language is: **`(1⁺0)*1*`** — zero or more groups of (one-or-more 1s followed by exactly one 0), optionally ending with more 1s. Two consecutive 0s always reject.

### The OCaml concept: `let rec ... and ...`

```ocaml
let rec init l = ...     (* init can call accept *)
and accept l = ...       (* accept can call init *)
```

Without `and`, OCaml processes definitions top-to-bottom, so `accept` wouldn't be visible inside `init`. The `and` keyword makes both functions visible to each other — **mutual recursion**.

### Connection to the bigger picture

In `la/manual/`, each scanner (for identifiers, numbers, keywords) will be an FSM just like this. But instead of returning `true`/`false` directly, they'll return `State(next_function)` or `Terminate(true/false)` — a protocol that lets the lexer run **multiple FSMs in parallel** and pick the best match.

---

## Part C: `id` (lines 50-69) — FSM for identifiers

### Why this example?

This is directly relevant to lexing! Every programming language needs to recognise **identifiers** (`x`, `myVar`, `foo42`). This FSM is a simplified version of what the real identifier scanner in `la/manual/id.ml` will do.

### The code:

```ocaml
let id s =
  let rec one l =
    match l with
      [] -> false                  (* empty string is not an identifier *)
    | h :: t ->
      if (h >= 'A' && h <= 'Z') || (h >= 'a' && h <= 'z') then (two t)
      else false                   (* must start with a letter *)

  and two l =
    match l with
      [] -> true                   (* consumed everything → valid *)
    | h :: t ->
      if ... letter or digit ... then (two t)
      else false                   (* underscore, space, etc. → invalid *)
  in
  one (list_of_string s)
```

### The two states and their purpose:

| State | Its job | Why it exists |
|-------|---------|---------------|
| `one` | Require exactly one letter to start | Identifiers MUST start with a letter, not a digit |
| `two` | Accept remaining letters/digits | After the first letter, digits are OK too |

### Traces:

| Input | Trace | Result | Why |
|-------|-------|--------|-----|
| `"foo42"` | one→two→two→two→two→two→`[]` | ✅ | Letter start, then letters+digits |
| `"123abc"` | one: `'1'` not a letter | ❌ | Can't start with digit |
| `"_x"` | one: `'_'` not a letter | ❌ | Underscore not allowed |
| `""` | one: `[]` → false | ❌ | Empty string is not an identifier |

### Connection to the bigger picture

In `la/manual/id.ml`, you'll see this EXACT same FSM, but rewritten to use:
- **Lazy streams** instead of lists (so we don't load the whole input into memory)
- **Lookahead** (peeking at the next character before deciding)
- **The `State` return type** (so the lexer can drive it externally)

The logic is identical. The machinery around it changes.

---
---

# FILE 2: `la/fsm/tree.ml`

[Open tree.ml](file:///Users/krishdave/Documents/Krish%20Stuff/8th%20Semester/Programming%20Languages/Pratham_Codes/Programming-Languages/PLDI/la/fsm/tree.ml)

## Why is a tree file in the lexer folder?

This file is **not about lexing**. It's here to reinforce the OCaml concept of **mutual recursion on data types** using `type ... and ...`. But it actually foreshadows something important for **Phase 2 (Parsing)** and **Phase 3 (Semantics)**.

In Phases 2 and 3, the core data structure is an **Abstract Syntax Tree (AST)** — a tree where each node represents an operation. For example, `1 + 2 * 3` becomes:

```
    Add
   /   \
  1    Mul
      /   \
     2     3
```

This file teaches you to think about **trees as recursive data types** and to process them with **mutually recursive functions** — exactly the skills you'll need for ASTs.

### The types:

```ocaml
type tree   = Leaf | Node of int * forest
and  forest = Empty | Cons of tree * forest
```

A `tree` contains a `forest` (its children), and a `forest` is a list of `tree`s. They reference each other, so they need `and`.

### The example tree (lines 22-33):

```
        10
       /  \
      5    3
           |
          Leaf
```

### The mutually recursive functions:

```ocaml
let rec sum_tree t =
  match t with
  | Leaf -> 0
  | Node (v, f) -> v + sum_forest f      (* tree calls forest *)

and sum_forest f =
  match f with
  | Empty -> 0
  | Cons (t, rest) -> sum_tree t + sum_forest rest   (* forest calls tree *)
```

**Trace**: `sum_tree example_tree`
```
sum_tree Node(10, ...)
= 10 + sum_forest (Cons(Node(5,Empty), Cons(Node(3,...), Empty)))
= 10 + sum_tree Node(5,Empty) + sum_forest (Cons(Node(3,...), Empty))
= 10 + (5 + sum_forest Empty) + (sum_tree Node(3,...) + sum_forest Empty)
= 10 + (5 + 0) + (3 + 0 + 0)
= 18
```

### Connection to the bigger picture

| Concept in `tree.ml` | Where you'll see it again |
|---|---|
| `type tree ... and forest` | `type expr = Add of expr * expr \| Const of int` in `semantics/*/expression.ml` |
| `sum_tree` / `sum_forest` | `eval` function in every interpreter — walks the AST recursively |
| `Node(value, children)` | `Add(left, right)`, `If(cond, then_branch, else_branch)` |

---
---

# What's Next?

We've now covered the **concept demos** (`la/fsm/`). The key takeaways:

1. **FSMs are the theory behind lexers** — that's why we study them first
2. **Each state = a function, each transition = a function call** (mutual recursion)
3. **Trees and mutual recursion** will return in Phases 2 and 3 for ASTs

Next up: `la/manual/` — where we build a **real, modular lexer** using these FSM ideas, but with proper infrastructure (lazy streams, lookahead, multi-scanner orchestration).

> I'll continue with `mystream.ml`, `state.ml`, and the scanner files in the next part. Let me know when you're ready!
