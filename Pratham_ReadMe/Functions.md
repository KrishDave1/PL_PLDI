## Types of Functions in OCaml (including Partial Application)

In OCaml, functions are first-class values. They can be stored, passed, and returned like normal values.

---

# 1. Simple Function

A basic function taking arguments and returning a value.

```
utop # let add x y = x + y;;
val add : int -> int -> int = <fun>
```

```
utop # add 2 3;;
- : int = 5
```

---

# 2. Anonymous Function (Lambda)

Function without a name.

```
utop # fun x -> x * 2;;
- : int -> int = <fun>
```

```
utop # (fun x -> x * 2) 4;;
- : int = 8
```

---

# 3. Curried Function

OCaml functions are curried by default.

```
utop # let add x y = x + y;;
val add : int -> int -> int = <fun>
```

Type means:

```
int -> (int -> int)
```

Function takes one argument at a time.

---

# 4. Partial Application

Applying only some arguments of a function to create a new function.

Example:

```
utop # let add x y = x + y;;
```

Apply one argument:

```
utop # let add5 = add 5;;
val add5 : int -> int = <fun>
```

Now:

```
utop # add5 3;;
- : int = 8
```

Here:

* `add` needs two arguments
* Only one argument given
* New function created

This is called **partial application**.

It works because OCaml functions are curried.

---

# 5. Higher-Order Function

A function that takes another function or returns a function.

```
utop # let apply f x = f x;;
val apply : ('a -> 'b) -> 'a -> 'b = <fun>
```

```
utop # apply (fun x -> x + 1) 5;;
- : int = 6
```

---

# 6. Recursive Function

Function calling itself.

```
utop # let rec fact n =
         if n = 0 then 1
         else n * fact (n-1);;
val fact : int -> int = <fun>
```

```
utop # fact 5;;
- : int = 120
```

---

# 7. Polymorphic Function

Works for any type.

```
utop # let id x = x;;
val id : 'a -> 'a = <fun>
```

```
utop # id 10;;
utop # id "hi";;
```

---

# 8. Function Returning Function

```
utop # let make_adder x =
         fun y -> x + y;;
val make_adder : int -> int -> int = <fun>
```

```
utop # let add10 = make_adder 10;;
utop # add10 5;;
- : int = 15
```

---

# 9. Tuple Argument Function

Takes tuple as single argument.

```
utop # let add_pair (x,y) = x + y;;
val add_pair : int * int -> int = <fun>
```

```
utop # add_pair (2,3);;
- : int = 5
```

---

# 10. Unit Function

Function with no meaningful input.

```
utop # let greet () = "Hello";;
val greet : unit -> string = <fun>
```

```
utop # greet ();;
- : string = "Hello"
```

---

# Final List of Function Types

1. Simple function
2. Anonymous (lambda) function
3. Curried function
4. Partial application
5. Higher-order function
6. Recursive function
7. Polymorphic function
8. Function returning function
9. Tuple-argument function
10. Unit function

---

# Key Concept

Partial application works because:

* OCaml functions are curried
* Supplying fewer arguments creates a new function automatically
