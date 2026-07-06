## function
[cons](http://clhs.lisp.se/Body/f_cons.htm) as a function creates a new cons (class). It accepts two objects, which it will combine into one cons, where object 1 is the [[car]] and object 2 is the [[cdr]], which can be represented in list form as (o1 . o2).
## class
[cons](http://clhs.lisp.se/Body/t_cons.htm) as a class is one of the main data structures in lisp. Its made of a car and cdr, and just has those two slots. Linking a second cons in either the car but more commonly in the cdr slot is how lists are formed.

A representation of three cons in the book I used (Touretzky, 2013).
![[Pasted image 20260704014700.png]]