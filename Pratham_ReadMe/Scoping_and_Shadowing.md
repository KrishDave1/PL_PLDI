### Scoping

**Scoping** refers to the region of a program where a variable or identifier can be accessed.
It determines the visibility and lifetime of variables in a program.

Scoping answers: *Where can a variable be used?*

---

### Types of Scoping

#### 1. Lexical (Static) Scoping

In lexical scoping, the scope of a variable is determined by the structure of the program code.
A variable is accessible within the block in which it is declared and its inner blocks.

Most modern programming languages use lexical scoping such as OCaml, C, C++, Java and Python.

Example:

```
let x = 10 in
let y = x + 5 in
y
```

Here, `y` can access `x` because `x` is defined in the outer scope.

---

#### 2. Dynamic Scoping

In dynamic scoping, the scope of a variable is determined at runtime based on the function call sequence.
A function uses the most recent value assigned during execution.

Example (conceptual):

```
x = 10

function A() {
  print(x)
}

function B() {
  x = 20
  A()
}

B()
```

If dynamic scoping is used, A prints 20 because it accesses the most recent value of `x`.

---

### Shadowing

**Shadowing** occurs when a variable declared in an inner scope has the same name as a variable in an outer scope, thereby hiding the outer variable.

The outer variable still exists but cannot be accessed in the inner scope.

Example:

```
let x = 10 in
let x = 20 in
x
```

The inner `x` shadows the outer `x`, so the result is 20.

---

### Types of Shadowing

#### 1. Variable Shadowing

An inner variable hides an outer variable with the same name.

```
let x = 5 in
let x = 8 in
x
```

---

#### 2. Parameter Shadowing

A function parameter hides a variable outside the function.

```
let x = 10
let f x = x + 1
```

The parameter `x` shadows the outer `x`.

---

#### 3. Function Shadowing

A variable hides a function with the same name.

```
let f x = x + 1;;
let f = 10;;
```

Now `f` refers to a variable, not the function.

---

#### 4. Block or Local Shadowing

A variable declared inside a block hides an outer variable.

Example (C/Java style):

```
int x = 5;
{
   int x = 10;
   printf("%d", x);
}
```

The inner `x` shadows the outer `x`.

---

#### 5. Class/Field Shadowing (OOP)

A subclass variable hides a parent class variable.

Example (Java):

```
class Parent {
    int x = 10;
}

class Child extends Parent {
    int x = 20;

    void show() {
        System.out.println(x);        // child x
        System.out.println(super.x);  // parent x
    }
}

public class Main {
    public static void main(String[] args) {
        Child c = new Child();
        c.show();
    }
}
```

Output:

```
20
10
```

The child class variable `x` shadows the parent class variable `x`.

---

### Difference between Scoping and Shadowing

Scoping defines where a variable can be accessed in a program.
Shadowing occurs when a new variable with the same name hides an existing variable in an outer scope.
