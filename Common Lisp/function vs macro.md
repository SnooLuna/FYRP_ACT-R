---
aliases:
  - function
  - macro
tags:
  - small
---
It can sometimes be important to distinguish functions and macros (to be more precise, macro functions), especially when you're coming from a language like python. Both functions and macros are pieces of code that are passed arguments and return a value. The differences between the two are small, and not entirely necessary to understand what ACT-R is doing. Still, it can sometimes be confusing, which is why I provide a short explanation here.

A function is evaluated at runtime. This means the arguments of a function are evaluated before calling the function. A macro is evaluated at compile time. When the lisp compiler evaluates a macro, it generates new code, inserting the values of the macro's forms into the code directly. As I understand it, it has similar pros and cons to function templates in C++.

One example are the function [[every]] and the macro [[and]]. They perform the same function, but are of different types. The structure of 'and' is written as such: `and` _{form}*_ ⇒ _{result}*_, whereas 'every' looks like this: `every` _predicate &rest sequences^+_ ⇒ _generalized-boolean_
