---
aliases:
  - equal-chunks
  - external-equal-chunks-fct
---
# Function description
This function checks if two chunks are equal, but does this by just calling [[chunk-equal-test]]. The difference between these two functions is that this can be called with just the names of the chunks, while chunk-equal-test requires the chunks themselves to be passed.
# Code
```
(defmacro equal-chunks (chunk-name1 chunk-name2)
  "Return t if two chunks are of the same chunk-type and have equal slot values"
  `(equal-chunks-fct ',chunk-name1 ',chunk-name2))
```

```
(defun equal-chunks-fct (chunk-name1 chunk-name2)
  "Return t if two chunks are of the same chunk-type and have equal slot values"
  (let ((c1 (get-chunk-warn chunk-name1))
        (c2 (get-chunk-warn chunk-name2)))
    (chunk-equal-test c1 c2)))
```




There's also an ACT-R command that does this (equal-chunks), using the code below (not super interesting)

```
(defun external-equal-chunks-fct (c1 c2)
  (equal-chunks-fct (string->name c1) (string->name c2)))

  

(add-act-r-command "equal-chunks" 'external-equal-chunks-fct "Return whether the two named chunks are equivalent. Params: chunk-name-1 chunk-name-2" nil)
```