## Equality Operator Logic (OCaml)

In OCaml, equality is not assignment. It is comparison.
There are **two main equality operators**, and they behave differently.

---

# 1. Structural Equality (`=`)

Compares **values structurally**.
It checks whether two values have the same content.

Syntax:

```
a = b
```

Returns:

```
bool
```

### Example 1: Integers

```
10 = 10;;
```

Result:

```
true
```

### Example 2: Strings

```
"abc" = "abc";;
```

Result:

```
true
```

### Example 3: Lists

```
[1;2;3] = [1;2;3];;
```

Result:

```
true
```

Even if they are different objects in memory, structural equality returns true if contents are same.

This is the equality you normally use.

---

# 2. Physical Equality (`==`)

Checks whether two values are the **same object in memory**.

Syntax:

```
a == b
```

Used mostly with:

* references
* mutable data

### Example

```
let a = ref 10;;
let b = ref 10;;

a = b;;    (* structural equality *)
```

Result:

```
true
```

But:

```
a == b;;   (* physical equality *)
```

Result:

```
false
```

Because:

* `a` and `b` store same value (10)
* But they are different memory locations

Now:

```
let c = a;;
a == c;;
```

Result:

```
true
```

Because both refer to same memory.

---

# Important Difference

| Operator | Meaning             | What it compares |
| -------- | ------------------- | ---------------- |
| `=`      | Structural equality | Values/content   |
| `==`     | Physical equality   | Memory identity  |

---

# Why Your Earlier Example Returned True

```
let x = "IIITB";;
x = "IIITB";;
```

* `=` compares string content
* Both strings have same characters
* So result is `true`

---

# Assignment vs Equality in OCaml

* `let x = 10` → binding (not assignment)
* `=` → comparison
* `:=` → assignment for mutable references

Example:

```
let r = ref 5;;
r := 10;;
```

Here `:=` changes the stored value.

---

### Equality Operator Behaviour in OCaml

OCaml is **strongly and statically typed**, so equality comparisons must follow strict type rules.

There is only **one structural equality operator**:

```
=
```

It compares two values of the **same type** and returns a boolean.

---

# 1. Equality with Integers

```
1 = 3;;
```

Output:

```
false
```

Explanation:

* Both are integers
* Values are different
* So result is false

---

# 2. Equality with Floats

```
1.0 = 3.0;;
```

Output:

```
false
```

Explanation:

* Both are floats
* Comparison is allowed
* Values differ → false

---

# 3. Comparing Different Types (int vs float)

```
1.0 = 3;;
```

Error:

```
This expression has type int but an expression was expected of type float
```

Explanation:

* OCaml does not automatically convert types
* `1.0` is float
* `3` is int
* Comparison requires same type

So this is invalid.

Correct comparison:

```
1.0 = float_of_int 3;;
```

---

# 4. No Separate Float Equality Operator

You tried:

```
1.0 =. 3.0;;
```

Error:

```
Unbound value =.
```

Explanation:

* OCaml has `+.` `-.` `*.` `/.` for float arithmetic
* But equality operator is only `=`
* There is no `=.` operator

So float comparison also uses:

```
=
```

Example:

```
2.5 = 2.5;;
```

Result:

```
true
```

---

# 5. Why OCaml is Strict

OCaml avoids implicit conversion like:

* converting int to float automatically

This prevents bugs and keeps typing safe.

So:

* int compared only with int
* float compared only with float
* string with string

---

# Final Key Points

1. `=` is structural equality operator
2. Works only when both operands have same type
3. No automatic int–float conversion
4. No separate float equality operator (`=.` does not exist)
5. Returns boolean (`true` or `false`)

# Final Concept Summary

OCaml has:

* Structural equality (`=`)
* Physical equality (`==`)
* Mutable assignment (`:=`)
* Immutable binding (`let`)

That is the complete equality logic in OCaml.

