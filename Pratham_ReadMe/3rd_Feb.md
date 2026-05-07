### Concepts demonstrated in the given OCaml snippets

---

# 1. Function using external variable (Lexical scoping)

```
let getx () = x;;
val getx : unit -> int = <fun>
```

This shows:

* Function definition
* Unit argument `()`
* Use of external variable `x`
* Lexical/static scoping

Meaning:

```
getx : unit -> int
```

Takes no meaningful input and returns an integer.

Concept:
Function can access variables from surrounding scope (lexical scoping).

---

# 2. List construction using cons operator

```
1 :: [2; 3];;
- : int list = [1; 2; 3]
```

`::` is called the **cons operator**.

Meaning:

* Adds element to front of list
* Constructs a new list

General form:

```
element :: list
```

Example:

```
5 :: [6;7]  →  [5;6;7]
```

Concept:
List construction and immutability of lists.

---

# 3. Explicit Type Conversion (string_of_int etc.)

OCaml does not automatically convert types.
You must explicitly convert.

### int → string

```
string_of_int 5;;
- : string = "5"
```

### float → string

```
string_of_float 3.14;;
```

### bool → string

```
string_of_bool true;;
```

### string → int

```
int_of_string "10";;
```

### string → float

```
float_of_string "3.5";;
```

### int → float

```
float_of_int 5;;
```

Concept:
OCaml requires **explicit type conversion**
(no implicit casting).

---

# 4. User-defined Recursive Data Type (Algebraic Data Type)

```
type mylist = Empty | NonEmpty of int * mylist
```

This defines a custom list type.

Two constructors:

* `Empty`
* `NonEmpty (int * mylist)`

This is a **recursive variant type**.

Example value:

```
val l1 : mylist = NonEmpty (1, NonEmpty (2, Empty))
```

Represents:

```
1 -> 2 -> Empty
```

Concept:

* Algebraic data types (variant types)
* Recursive data structures
* Custom list implementation

---

# 5. Function on user-defined type

```
val sumlist : mylist -> int = <fun>
```

Function takes `mylist` and returns int.
Likely sums all elements.

Concept:
Functions operating on user-defined recursive types.

---

# 6. Unit Type and Functions Returning Unit

```
val main : unit -> unit = <fun>
```

Means:

* Takes unit `()`
* Returns unit `()`

Used when function performs actions but returns no meaningful value.

Example:

```
let main () = print_endline "Hello";;
```

Call:

```
main ();;
```

Output type:

```
- : unit = ()
```

Concept:

* Unit type represents “no meaningful value”
* Similar to void in C/C++

---

# 7. Final Concepts Demonstrated

This full set demonstrates:

1. Lexical scoping in functions
2. Unit type and unit functions
3. List construction using `::`
4. Explicit type conversion (no implicit casting)
5. User-defined algebraic data types
6. Recursive data structures
7. Functions on custom types
8. Functions returning unit `(unit -> unit)`
