## Method Resolution Order (MRO)

Method Resolution Order answers one question:

> When a method is called, which implementation is chosen?

This matters when:

* A class inherits from another class
* Multiple classes define the same method
* Multiple inheritance exists

---

# 1. Simple Case: Single Inheritance

In single inheritance (Java, OCaml objects, basic C++), it is simple.

Example in Java:

```java
class A {
    void f() { System.out.println("A"); }
}

class B extends A {
    void f() { System.out.println("B"); }
}
```

Now:

```java
A x = new B();
x.f();
```

Which method runs?

Answer: `B.f()`

Why?

Because method lookup checks:

```
Actual object type → then parent → then parent’s parent
```

So MRO is:

```
B → A → Object
```

First match wins.

---

# 2. Why MRO Becomes Important

It becomes tricky when **multiple inheritance** exists.

Example in Python:

```python
class A:
    def f(self): print("A")

class B(A):
    pass

class C(A):
    def f(self): print("C")

class D(B, C):
    pass
```

Now:

```python
D().f()
```

Which `f` runs?

This depends on MRO.

---

# 3. Python’s MRO

Python uses **C3 linearization**.

For:

```python
class D(B, C)
```

The MRO becomes:

```
D → B → C → A → object
```

So lookup order is:

1. Check D
2. Check B
3. Check C
4. Check A
5. Check object

Since C defines `f`, result is:

```
C
```

You can check in Python:

```python
D.__mro__
```

---

# 4. General Rule of MRO

When method is called:

```
1. Look in the object’s class
2. If not found, follow MRO order
3. First match stops search
```

---

# 5. Diamond Problem

Classic case:

```
      A
     / \
    B   C
     \ /
      D
```

If both B and C override a method from A:

Which one should D use?

MRO ensures:

* Deterministic order
* No ambiguity
* No duplicate visits

Python's C3 guarantees consistent ordering.

---

# 6. Static vs Dynamic in MRO

MRO defines the lookup order.

Dynamic dispatch means:

> The method is chosen at runtime based on actual object.

MRO + dynamic dispatch together decide:

> Which method body actually runs.

---

# 7. Short Definition (Exam Style)

> Method Resolution Order (MRO) is the order in which a programming language searches classes to find a method when it is invoked on an object, especially in the presence of inheritance.

---

If you want, I can next:

* Show C3 linearization step-by-step
* Compare MRO in C++ vs Python
* Draw the diamond case clearly
* Relate it to vtables in C++


Yes — **the order can differ depending on the language rules**, but in a given language it is fixed and not arbitrary.

Let’s clarify carefully.

You’re asking:

> Can MRO be D → C → B → A instead of D → B → C → A?

Answer:

* In some languages: yes
* In Python: depends on inheritance order
* But once defined, MRO is deterministic (not random)

---

# 1. Example structure

Diamond inheritance:

```
      A
     / \
    B   C
     \ /
      D
```

Now suppose:

```
B and C both inherit A
D inherits from B and C
```

The key is: **how D is declared**

---

# 2. Case 1: Python — order depends on class definition

### If defined as:

```python
class D(B, C):
    pass
```

Then MRO:

```
D → B → C → A → object
```

Search order:

```
D then B then C then A
```

---

### If defined as:

```python
class D(C, B):
    pass
```

Then MRO becomes:

```
D → C → B → A → object
```

So yes — it can be:

```
D → C → B → A
```

It depends on order in class declaration.

---

# 3. Why this rule exists

Python follows:

> Left-to-right priority + consistent hierarchy

Meaning:

* First parent gets priority
* But hierarchy must remain logical
* No class visited before its parent

Python uses C3 linearization to guarantee consistency.

---

# 4. Can it randomly switch between them?

No.

Once class is defined:

```
class D(B, C)
```

The MRO is permanently fixed as:

```
D → B → C → A
```

It will NOT sometimes become:

```
D → C → B → A
```

MRO must be deterministic.

---

# 5. In C++?

C++ multiple inheritance does not use Python-style linear MRO.

Instead:

* It follows inheritance paths
* Uses scope resolution
* Virtual inheritance changes behavior

So C++ lookup is more complex and not a single linear MRO list like Python.

---

# 6. Key idea to remember

MRO is determined by:

1. Language rules
2. Order of parent classes in definition

Example:

```
class D(B, C) → D → B → C → A
class D(C, B) → D → C → B → A
```

But once defined:

> MRO never changes at runtime.

---

# 7. One-line exam answer

> Method Resolution Order depends on the inheritance order specified in the class definition and follows language-specific rules, but once determined it remains fixed and deterministic.
