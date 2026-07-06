# Function description
gets the hash for a chunk from its name from the dictionary that is the chunks table in the model. (warn is in the name of the function because it gives a warning if the chunk doesn't exist)

# Code
```
(defun get-chunk (name)
  "Internal function for getting the chunk structure from its name"
  (verify-current-model
   "get-chunk called with no current model."
   (let ((model (current-model-struct)))
     (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
       (gethash name (act-r-model-chunks-table model))))))
```

```
(defun get-chunk-warn (name)
  "Internal function for getting the chunk structure from its name"
  (verify-current-model
   "get-chunk called with no current model."
   (let ((c (let ((model (current-model-struct)))
              (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
                (gethash name (act-r-model-chunks-table model))))))
     (if c c
       (print-warning "~s does not name a chunk in the current model." name)))))
```

