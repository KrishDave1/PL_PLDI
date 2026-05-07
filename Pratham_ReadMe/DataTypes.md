Below is a structured list of **OCaml data types** shown in **utop style**.

---

# 1. Primitive Types

Integer
```
utop # 10;;
- : int = 10
```

Float

```
utop # 3.14;;
- : float = 3.14
```

Boolean 

```
utop # true;;
- : bool = true
```

Charachter
```
utop # 'A';;
- : char = 'A'
```

String
```
utop # "hello";;
- : string = "hello"
```

---

# 2. Unit Type

Represents “no meaningful value”.

```
utop # ();;
- : unit = ()
```

---

# 3. Tuple

Fixed-size collection of possibly different types.

```
utop # (1, "hello", true);;
- : int * string * bool = (1, "hello", true)
```

---

# 4. List

Immutable homogeneous collection.

```
utop # [1;2;3];;
- : int list = [1; 2; 3]
```

Empty list:

```
utop # [];;
- : 'a list = []
```

---

# 5. Array

Mutable indexed collection.

```
utop # [|1;2;3|];;
- : int array = [|1; 2; 3|]
```

---

# 6. Option Type

Represents value or absence of value.

```
utop # Some 10;;
- : int option = Some 10
```

```
utop # None;;
- : 'a option = None
```

---

# 7. Reference Type

Mutable storage.

```
utop # ref 5;;
- : int ref = {contents = 5}
```

---

# 8. Function Type

Functions are first-class values.

```
utop # fun x -> x + 1;;
- : int -> int = <fun>
```

---

# 9. Record Type (User-defined)

```
utop # type student = {name:string; age:int};;
```

```
utop # {name="Aman"; age=20};;
- : student = {name = "Aman"; age = 20}
```

---

# 10. Variant Type (Algebraic Data Type)

```
utop # type color = Red | Green | Blue;;
```

```
utop # Red;;
- : color = Red
```

---

# 11. Polymorphic Type

Type variable `'a`

```
utop # let id x = x;;
val id : 'a -> 'a = <fun>
```

---

# Complete Classification

## Built-in Primitive Types

* int
* float
* bool
* char
* string
* unit

## Built-in Composite Types

* tuple
* list
* array
* option
* ref
* function

## User-defined Types

* record
* variant (algebraic data type)

## Polymorphic Types

* `'a`, `'b`, etc.

---

If you want, I can also separate them into primitive vs non-primitive vs user-defined clearly for exam format.
