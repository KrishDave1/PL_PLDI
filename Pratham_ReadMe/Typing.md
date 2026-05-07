Below is a **complete, well-structured list of typing classifications** with clear definitions and examples. You can directly use this in notes.

---

# Typing in Programming Languages

**Typing** is the system that classifies values and variables into types and checks whether operations on them are valid.

A type defines what kind of data a variable can store (int, float, string, etc.).

---

# 1. Static Typing

Type checking happens **at compile time** (before execution).

Errors are detected early.

Languages: OCaml, C, C++, Java.

Example (OCaml):

```
let x = 10;;
let y = x + 5;;
```

Invalid:

```
let x = 10 + "hello";;
```

Error occurs before running the program.

---

# 2. Dynamic Typing

Type checking happens **at runtime**.

A variable can hold different types during execution.

Languages: Python, JavaScript.

Example (Python):

```
x = 10
x = "hello"
```

---

# 3. Strong Typing

The language strictly enforces type rules.
No implicit mixing of unrelated types.

Example (OCaml):

```
10 + "5"
```

Error because int and string cannot be added.

OCaml, Python and Java are strongly typed.

---

# 4. Weak Typing

Allows implicit type conversion.

Example (C):

```
int x = 'A' + 1;
```

Character is automatically converted to integer.

---

# 5. Explicit Typing

Programmer must declare the type manually.

Example (C):

```
int x = 10;
float y = 5.5;
```

---

# 6. Implicit Typing (Type Inference)

Compiler automatically determines the type.

Example (OCaml):

```
let x = 10;;
let y = 3.14;;
```

OCaml infers:

* x : int
* y : float

---

# 7. Duck Typing

Type is determined by behavior (methods supported), not explicit declaration.

“If it behaves like a duck, it is a duck.”

Do not check class or declared type.
Use the object if it supports the required operation.

Only behavior matters.

Example (Python):

```
def add(a, b):
    return a + b
```

Works for:

* integers
* floats
* strings
  as long as `+` is valid.

---

# 8. Structural Typing

Type compatibility depends on structure (properties/methods), not name.

If two types have same structure, they are compatible.

Example (TypeScript concept):

```
type A = { x: number, y: number }
type B = { x: number, y: number }
```

A and B are compatible because structure is same.

---

# 9. Nominal Typing

Type compatibility depends on the declared name.

Even if structure is same, types are different.

Example (Java):

```
class A { int x; }
class B { int x; }
```

A and B are different types.

---

# 10. Gradual Typing

Mix of static and dynamic typing in the same language.

Example (TypeScript):

```
let x: number = 10;
let y;   // dynamic
```

Languages: TypeScript, Python (with type hints).

---

# 11. Dependent Typing (Advanced)

Type depends on a value.

Used in theorem provers and advanced languages.

Example (concept idea):

```
Vector(n)
```

Here type includes size `n`.

Languages: Idris, Coq.

---

# Final Organized Classification

### Based on When Type Checking Happens

* Static typing
* Dynamic typing

### Based on Strictness

* Strong typing
* Weak typing

### Based on Type Declaration Style

* Explicit typing
* Implicit typing (type inference)

### Based on Type Compatibility Rules

* Nominal typing
* Structural typing

### Based on Behavioral Checking

* Duck typing

### Mixed Systems

* Gradual typing

### Advanced Systems

* Dependent typing

---

If you want, I can also compress this into a 10-mark exam answer format.
