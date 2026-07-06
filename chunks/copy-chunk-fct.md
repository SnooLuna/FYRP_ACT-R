# Function description
This function copies an existing chunk.
# Code
[[function vs macro|Macro]] version that calls the function
```
(defmacro copy-chunk (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
  `(copy-chunk-fct ',chunk-name))
```

The actual function with the code that does it.
```
(defun copy-chunk-fct (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
```
First, a local variable `chunk` is defined, which stores the chunk retrieved by [[get-chunk-warn]]. The code only continues when a chunk has properly been retrieved, and ends by returning [[nil]] if not. The chunk is then held into a lock so no parallel code can change the chunk while we need it.
```
  (let ((chunk (get-chunk-warn chunk-name)))
    (when chunk
      (bt:with-recursive-lock-held ((act-r-chunk-lock chunk))
```
When the global parameter `use-short-copy-names` has been set to [[t]], the base name of the chunk needs to be set before we can continue. This has to do with the naming only and is not super important. The base-name of a chunk seems to be related to this short copy names parameter only.
```
        (when (use-short-copy-names)
          (unless (act-r-chunk-base-name chunk)
            (setf (act-r-chunk-base-name chunk) (concatenate 'string (symbol-name chunk-name) "-"))))
```
Then, we define two new local variables, one for the new name of the chunk and one for the chunk itself. The new name again depends on this `use-short-copy-names` parameter, but is based on the already existing base-name of the chunk, or the symbol-name of the chunk. The new chunk is then defined ([[act-r-chunk|make-act-r-chunk]]) with this new-name, a matching base-name, an empty list of chunks it has been merged with, the same slots as the chunk it's being copied from, undefined parameter values and the slot-value-lists from the chunk it is being copied from.
```
        (let* ((new-name (new-name-fct (if (use-short-copy-names)
                                           (act-r-chunk-base-name chunk)
                                         (concatenate 'string (symbol-name chunk-name) "-"))))
               (new-chunk (make-act-r-chunk
                           :name new-name
                           :base-name (act-r-chunk-base-name chunk)
                           :merged-chunks (list new-name)
                           :filled-slots (act-r-chunk-filled-slots chunk)
                           :parameter-values (bt:with-lock-held (*chunk-parameters-lock*)
                                               (make-array *chunk-parameters-count*
                                                           :initial-element *chunk-parameter-undefined*))
                           :slot-value-lists (copy-tree (act-r-chunk-slot-value-lists chunk)))))
```

```
          ;; Create the back links as needed
          (when (update-chunks-on-the-fly)
            (bt:with-recursive-lock-held ((act-r-model-chunk-lock (current-model-struct)))
```
for each slot in the slot-value-list, we save the slot name and the value of that slot in the chunk that is being copied to slot-name and old, using [[car]] and [[cdr]].
```
              (dolist (slot (act-r-chunk-slot-value-lists chunk))
                (let ((slot-name (act-r-slot-name (car slot)))
                      (old (cdr slot)))
```
Making sure `old` is a chunk, we save the backlinks of this chunk to the local variable `bl`.
```
                  (when (chunk-p-fct old)
                    (let ((bl (chunk-back-links old)))
```
If these backlinks are a hashtable, the 
```
                      (if (hash-table-p bl)
                          (push slot-name (gethash new-name bl))
                        (let ((ht (make-hash-table)))
                          (setf (gethash new-name ht) (list slot-name))
                          (setf (chunk-back-links old) ht)))))))))
```

```
          ;; update its parameters for only those that need it
          (let (copy-list undefined)
            (bt:with-lock-held (*chunk-parameters-lock*)
              (setf copy-list *chunk-parameters-copy-list*)
              (setf undefined *chunk-parameter-undefined*))
            (dolist (param copy-list)
              (if (act-r-chunk-parameter-copy param)
                  (let ((current (aref (act-r-chunk-parameter-values chunk) (act-r-chunk-parameter-index param))))
                    (setf (aref (act-r-chunk-parameter-values new-chunk) (act-r-chunk-parameter-index param))
                      (dispatch-apply (act-r-chunk-parameter-copy param)
                               (if (eq current undefined)
                                   (chunk-parameter-default param chunk-name)
                                 current))))
                (setf (aref (act-r-chunk-parameter-values new-chunk) (act-r-chunk-parameter-index param))
                  (dispatch-apply (act-r-chunk-parameter-copy-from-chunk param) chunk-name)))))
```

```
          ;; note the original
          (setf (act-r-chunk-copied-from new-chunk) chunk-name)
```

```
          ;; Put it into the main table
          (let ((model (current-model-struct)))
            (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
              (setf (gethash new-name (act-r-model-chunks-table model)) new-chunk)))
          new-name)))))
```