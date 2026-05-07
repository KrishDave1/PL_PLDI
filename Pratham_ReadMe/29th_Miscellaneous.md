Below is your content with the additional related concepts integrated clearly and completely.

---

The code demonstrates **tuples vs lists, heterogeneous vs homogeneous types, static typing, and type inference in OCaml**.

---

# 1. Tuples Can Store Different Types (Heterogeneous)

```
let t = (1, 2);;
val t : int * int = (1, 2)
```

Tuple of two integers.

```
let t = (1, 2.0);;
val t : int * float = (1, 2.)
```

Tuple can store different types:

* int
* float

Another example:

```
(1, "January", 2026);;
- : int * string * int = (1, "January", 2026)
```

So tuples are **heterogeneous**:

They can store values of different types together.

Type notation:

```
int * float * string
```

Important properties of tuples:

* Fixed size
* Order matters
* Types are fixed by position
* Can mix different types

---

# 2. Lists Must Have Same Type (Homogeneous)

```
[1; 2.];;
```

Error:

```
float but expected int
```

Because:

* `1` is int
* `2.` is float
* A list must contain only one type

Valid lists:

```
[1;2;3]        → int list
[1.0;2.0]      → float list
["a";"b"]      → string list
```

So lists are **homogeneous**:

All elements must be same type.

Important properties of lists:

* Ordered
* Immutable
* Can grow recursively
* All elements same type
* Written using semicolons `;`

---

# 3. Nested Lists (List of Lists)

```
let lol = [[1; 2]; [3; 4; 5]];;
val lol : int list list = [[1; 2]; [3; 4; 5]]
```

This is:

* a list
* whose elements are also lists

Type:

```
int list list
```

Meaning:
List of integer lists.

This shows:
Lists can be nested recursively.

---

# 4. Static Type Checking

OCaml checks types at compile time.

```
[1; 2.];;
```

Error occurs because:

* int and float cannot mix in list
* OCaml does not perform automatic conversion

This demonstrates:

* Strong typing
* Static typing
* No implicit coercion between int and float

---

# 5. Type Inference

You never explicitly wrote types, but OCaml inferred them:

```
val t : int * float
val lol : int list list
```

This demonstrates:
Implicit typing (type inference).

---

# Complete Concepts Demonstrated

This example demonstrates:

1. Tuple data type
2. Tuples are heterogeneous (different types allowed)
3. Lists are homogeneous (same type only)
4. Nested lists (recursive data structures)
5. Static typing
6. Strong typing
7. Type inference

---

# Short Exam Answer

This demonstrates tuples and lists in OCaml. Tuples are heterogeneous and can store different types, while lists are homogeneous and must contain elements of the same type. The example also shows static typing, strong type checking, nested lists, and type inference in OCaml.
