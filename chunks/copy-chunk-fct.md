# Function description
This function copies an existing chunk. 
# Code
[[function vs macro|Macro]] version that calls the function
```
(defmacro copy-chunk (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
  `(copy-chunk-fct ',chunk-name))
```



The actual function definition with the code that does it.
```
(defun copy-chunk-fct (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
```
First, a local variable `chunk` is defined, which stores the chunk retrieved by [[get-chunk|get-chunk-warn]]. The code only continues when a chunk has properly been retrieved, and ends by returning [[nil]] if not. The chunk is then held into a lock so no parallel code can change the chunk while we need it.
```
  (let ((chunk (get-chunk-warn chunk-name)))
    (when chunk
      (bt:with-recursive-lock-held ((act-r-chunk-lock chunk))
```
#### Updating the name and creating an empty new chunk
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

#### Updating the back links
The next part of the code handles the back links of this chunk, but is only run when the flag `update-chunks-on-the-fly` has been set to true.
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
If these backlinks are a hash table, the slot-name is simply pushed into the entry in the `bl` hash table that is associated with the key `new-name`. If `bl` is not a hash table, a new hash table is created, the new-name entry is created with the value being the slot-name, and the hash table is stored. 
```
                      (if (hash-table-p bl)
                          (push slot-name (gethash new-name bl))
                        (let ((ht (make-hash-table)))
                          (setf (gethash new-name ht) (list slot-name))
                          (setf (chunk-back-links old) ht)))))))))
```
This code is not necessary for understanding this project, but backlinks could be relevant.
#### Copying over the parameters 
Then, the parameters that were earlier created empty are updated with the values from the chunk this is being copied from. First, two empty local variables are created, and the parameters of the chunk are locked. Right after, those two local variables are set to the list of parameters that should be copied over and the undefined parameter value.
```
          ;; update its parameters for only those that need it
          (let (copy-list undefined)
            (bt:with-lock-held (*chunk-parameters-lock*)
              (setf copy-list *chunk-parameters-copy-list*)
              (setf undefined *chunk-parameter-undefined*))
```
Next, [[dolist]] will go over each parameter in the `copy-list`, and for each, checks if there is a function for copying this parameter over. Parameters can either be copied with these functions, or can simply be copied from chunk.
```
            (dolist (param copy-list)
              (if (act-r-chunk-parameter-copy param)
```
If there is a function for copying this parameter, the local variable `current` will store the current parameter value of the chunk to be copied, and the parameter that needs to be set is retrieved using [[aref]], after which the copy function is used through [[dispatch-apply]] to get a copy of the parameter value to set. If the parameter is undefined, the default value for this parameter is used.
```
                  (let ((current (aref (act-r-chunk-parameter-values chunk) (act-r-chunk-parameter-index param))))
                    (setf (aref (act-r-chunk-parameter-values new-chunk) (act-r-chunk-parameter-index param))
                      (dispatch-apply (act-r-chunk-parameter-copy param)
                               (if (eq current undefined)
                                   (chunk-parameter-default param chunk-name)
                                 current))))
```
If there is no such function listed, and we copy from chunk instead, [[dispatch-apply]] is again used to get the copied value to set into the parameter of the new chunk.
```
                (setf (aref (act-r-chunk-parameter-values new-chunk) (act-r-chunk-parameter-index param))
                  (dispatch-apply (act-r-chunk-parameter-copy-from-chunk param) chunk-name)))))
```
#### Updating copied-from
Now that the parameters have been copied over, the name of the old chunk is listed as the chunk this new one has been copied from. #potential
```
          ;; note the original
          (setf (act-r-chunk-copied-from new-chunk) chunk-name)
```
#### Storing the chunk.
And finally, the chunk is put into the hash table that stores all chunks in the current act-r model.
```
          ;; Put it into the main table
          (let ((model (current-model-struct)))
            (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
              (setf (gethash new-name (act-r-model-chunks-table model)) new-chunk)))
          new-name)))))
```