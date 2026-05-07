
### Polymorphic Type in OCaml

A **polymorphic type** is a type that can work with **many different types**, not just one specific type.

“Poly” means many.
So polymorphic means “many forms”.

---

# 1. Basic Idea

Instead of fixing a function to one type (like int), OCaml allows it to work for any type using **type variables**.

Type variables are written as:

```
'a
'b
'c
```

These are placeholders for any type.

---

# 2. Example: Identity Function

```
utop # let id x = x;;
val id : 'a -> 'a = <fun>
```

Meaning:

* Takes a value of type `'a`
* Returns a value of same type `'a`

`'a` means:

> any type

Now we can use it with different types:

```
utop # id 10;;
- : int = 10
```

```
utop # id "hello";;
- : string = "hello"
```

```
utop # id true;;
- : bool = true
```

Same function works for int, string, bool, etc.

This is called **parametric polymorphism**.

---

# 3. Polymorphic Lists

Empty list:

```
utop # [];;
- : 'a list = []
```

Meaning:

* It is a list of any type
* Type will be decided when used

Example:

```
utop # let l1 = [1;2;3];;
val l1 : int list = [1; 2; 3]
```

```
utop # let l2 = ["a";"b"];;
val l2 : string list = ["a"; "b"]
```

---

# 4. Example: Polymorphic Function with Two Types

```
utop # let first (x, y) = x;;
val first : 'a * 'b -> 'a = <fun>
```

Meaning:

* Takes a tuple of two possibly different types
* Returns first element

Works for:

```
first (1, "hello");;
```

Returns:

```
1
```

---

# 5. Why Polymorphism is Useful

* Code reuse
* More general functions
* Safer and flexible programs
* No need to rewrite same logic for different types

---

# 6. Important Rule

In parametric polymorphism:

* Function treats values uniformly
* It cannot assume anything about `'a`

For example:

```
let f x = x + 1;;
```

This is NOT polymorphic.

Output:

```
val f : int -> int
```

Because `+` only works on integers.

---

# 7. Types of Polymorphism (For Theory)

1. Parametric polymorphism (most common in OCaml)
2. Ad-hoc polymorphism (operator overloading, not typical in OCaml)
3. Subtype polymorphism (object-oriented languages)

OCaml mainly uses **parametric polymorphism**.

---

# Final Definition (Exam Ready)

A polymorphic type is a type that contains type variables (like `'a`) and allows a function or data structure to operate on values of different types while maintaining type safety.
