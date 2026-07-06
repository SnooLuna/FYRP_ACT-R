---
aliases:
  - chunk-copied-from-fct
  - external-chunk-copied-from
---
# Function Description
This group of macro/act-r command/functions return the name of the chunk from which the provided chunk was copied. 
# Code
[[function vs macro|Macro]] version that calls the function
```
(defmacro chunk-copied-from (chunk-name)
  "Return the name of the chunk from which the provided chunk was copied"
  `(chunk-copied-from-fct ',chunk-name))
```

Function version that contains the actual important code.
```
(defun chunk-copied-from-fct (chunk-name)
  "Return the name of the chunk from which the provided chunk was copied"
  (let ((chunk (get-chunk-warn chunk-name)))
    (when chunk
      (let ((copied-from (bt:with-recursive-lock-held ((act-r-chunk-lock chunk)) (act-r-chunk-copied-from chunk))))
        (values
         (when (and copied-from (chunk-p-fct copied-from) (equal-chunks-fct chunk-name copied-from))
           copied-from)
         copied-from)))))
```

Another function version that's a little safer so it can be called by the user of act-r using the commands.
```
(defun external-chunk-copied-from (chunk-name)
  (chunk-copied-from-fct (string->name chunk-name)))

(add-act-r-command "chunk-copied-from" 'external-chunk-copied-from "Returns the name of the chunk from which the given chunk was copied. Params: chunk-name.")
```