---
tags:
  - big
---
## Function description
chunk-slot-equal checks whether two chunk slots have equal values. This function is used by passing the values of two slots to the function.
## Code
The function is defined, with name chunk-slot-equal, and input variables val1 and val2, standing for the two slot values that will be compared.
```
(defun chunk-slot-equal (val1 val2)
```

First, [[eq]] is used to check if the two values are the exact same object. If this is the case, the function returns [[t|true]] and the function ends. 
```
  (if (eq val1 val2)
      t
```
If the values are not the same object, we define two local variables, c1 and c2 that we use for... something 
```
    (let (c1 c2)
```
After defining these local variables, we start a [[cond]]itional, where each part checks whether the two values are the same for three different cases. When the two values are chunks, strings or any other case.

The first argument checks for chunks being the same. 
It does this by, first locking the act-r model to securely access the chunks so they don't change while we are accessing them, then setting the values of the previously defined c1 and c2 to the chunks associated with the names that were passed, and then checking if those two chunks are the same exact object. If this returns true, the entire functions returns true.
```
      (cond ((bt:with-recursive-lock-held ((act-r-model-chunk-lock (current-model-struct)))
               (and (setf c1 (get-chunk val1))  
                    (setf c2 (get-chunk val2))))
             (eq c1 c2))
```
The second cond argument checks for strings being the same. It does this by checking if val1 is a string, and it so, it then checks if val2 is a string and then whether val1 and val2 are the same string. If this returns true, the entire functions returns true.
```
            ((stringp val1)
             (and (stringp val2) (string-equal val1 val2)))
```
Finally, the third argument checks any other case, simply using [[equalp]]
```
            (t (equalp val1 val2))))))
```



There is also an external ACT-R command that does this called "chunk-slot-equal", which calls a safer version of this, using the code below. It's not necessary to understand this.
```
(defun external-chunk-slot-equal (val1 val2)
  (chunk-slot-equal (decode-string-names val1) (decode-string-names val2)))

  
(add-act-r-command "chunk-slot-equal" 'external-chunk-slot-equal "Returns whether the provided items are considered equal values for chunk slots. Params: 'val1' 'val2'.")
```
