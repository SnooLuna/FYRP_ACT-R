---
tags:
  - small
---
([aref](http://clhs.lisp.se/Body/f_aref.htm#aref) array index)
**aref** _array &rest subscripts_ => _element_

aref takes an array and indices and then gets the value at those indices in that array. If there's no indices given and there's only one element it will just return the singular element.