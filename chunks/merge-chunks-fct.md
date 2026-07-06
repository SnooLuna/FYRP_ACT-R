## Function description
This function merges two chunks into a single representation

## Code
The function is defined, accepting the names of two chunks to be compared.
```
(defun merge-chunks-fct (chunk-name1 chunk-name2)
```
First it gets the actual chunks using [[get-chunk|get-chunk-warn]], and saves both of those chunk representations to the local variables `c1` and `c2`.
```
  (let ((c1 (get-chunk-warn chunk-name1))
        (c2 (get-chunk-warn chunk-name2)))
```
with (when (and c1 c2), it makes sure both chunks got retrieved correctly, one of the chunks being [[nil]] will skip the rest of the code.
```
    (when (and c1 c2)
```
Then, there are checks to make sure these two chunks should be merged. Making use of [[chunk-equal-test]], the code will return [[nil]] if the chunks do not have the exact same contents, and if the two chunks are the exact same object already, they do not need merging, so if this is the case the rest of the code is simply skipped. 
```
      (unless (chunk-equal-test c1 c2)
        (return-from merge-chunks-fct nil))
      (unless (eq c1 c2)
        (bt:with-recursive-lock-held ((act-r-chunk-lock c1))
          (bt:with-recursive-lock-held ((act-r-chunk-lock c2))
```
If the two chunks were retrieved correctly, and they are mergeable (they have the same contents but are not the same object already), the objects are held with a lock so they're not changed by any other code running in parallel.

After this, there are four !!!!!!!!!
#### Merging the parameters into c1
The parameters are held into a lock [[dolist]] will execute the following code on all the parameters listed in `chunk-parameters-merge-list`, which is a list of all the parameters that have a merge function.
```
            (dolist (param (bt:with-lock-held (*chunk-parameters-lock*)
                             *chunk-parameters-merge-list*))
```
These parameters with a merge function are looked up by index in c1, and that value is going to be set by the code that comes next.
```
              (setf (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param))
```
`act-r-chunk-parameter-merge` retrieves the merge function associated with this parameter, and [[case]] is used to decide what to do with this function.
```
                (case (act-r-chunk-parameter-merge param)
```

If the merge function matches `second`:
```
                  (:second
```
save the value of the parameter in c2 that matches the name of the parameter we are currently handling to temporary value v
```
                   (let ((v (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
```
If this parameter is undefined in c2, it returns the default parameter value for that chunk type, if it is defined, the parameter that was just retrieved is returned and saved in c1 through the `setf` from earlier. 
```
                     (if (eq v *chunk-parameter-undefined*)
                         (chunk-parameter-default param chunk-name2)
                         v)))
```

If the merge function matches `second-if`:
```
                  (:second-if
```
Do the same thing as the `second` clause above, but the other way around. 
First we again save the value of the parameter we're handling of c2 into a temporary local variable v.
```
                   (let ((v (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
```
First check if it's undefined (if so set default), and then if v is not [[nil]], we return the value of v, otherwise return the value of this parameter in c1 instead. This returned value is then set to be the new parameter value in c1 through the `setf` from before the [[case]] started.
```
                     (when (eq v *chunk-parameter-undefined*)
                       (setf v (chunk-parameter-default param chunk-name2)))
                     (if v
                         v
                       (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param)))))
```
the default case that happens if the merge was neither `second` nor `second-if`:
Use [[dispatch-apply]] to apply the merge function that is associated with this parameter to merge the parameter of chunk 1 and chunk 2.
```
                  (t
                   (dispatch-apply (act-r-chunk-parameter-merge param) chunk-name1 chunk-name2)))))                
```

#### Merging the parameter values into c1
Go through all parameters again (with a lock to keep things safe), this time taking them from the internal list of parameters that have a merge value function.
```
            (dolist (param (bt:with-lock-held (*chunk-parameters-lock*)
                             *chunk-parameters-merge-value-list*))
```
Set the value of that parameter within chunk 1 to what the next pieces of code will find for us.
```
              (setf (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param))
```
first create temp variables c1-val and c2-val that are the values for this parameter associated with chunk 1 and chunk 2
```
                (let ((c1-val (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param)))
                      (c2-val (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
```
Using [[dispatch-apply]], the merge value function is applied to the values of that parameter for chunk 1 and chunk 2. If either of these values is undefined for that chunk, the default value for that parameter will be passed to the merging function instead.
```
                  (dispatch-apply (act-r-chunk-parameter-merge-value param)
                                  (if (eq c1-val *chunk-parameter-undefined*)
                                      (chunk-parameter-default param chunk-name1)
                                    c1-val)
                                  (if (eq c2-val *chunk-parameter-undefined*)
                                      (chunk-parameter-default param chunk-name2)
                                    c2-val)))))
```

#### Chunk 2 has been merged into chunk 1, now chunk 2 needs to be safely removed.
This part mostly has comments by the author, so I will not add much explanation here.

If one of c1 or c2 was not allowed to be changed, this rule applies to the merged chunk too.
```
            ;; If either is immutable then the result should be as well.
            ;; Since c1 will maintain its immutability need to check if c2
            ;; is immutable and then make c1 immutable if c2 is.
            
            (when (act-r-chunk-immutable c2)
              (setf (act-r-chunk-immutable c1) t))
```

Any mention of chunk 2 needs to be updated to the mention of chunk 1.
```
            ;; For any chunks which had been merged with c2 also remap them
            ;; and indicate them in c1
            (let ((model (current-model-struct)))
              (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
                (dolist (x (act-r-chunk-merged-chunks c2))
                  (setf (gethash x (act-r-model-chunks-table model)) c1)
                  (push x (act-r-chunk-merged-chunks c1)))
                  
                ;; When name-remapping is on
                (when (update-chunks-on-the-fly)
                
                  ;; delete all back-links to the c2 chunk
                  (dolist (slots (act-r-chunk-slot-value-lists c2))
                    (let ((slot-name (act-r-slot-name (car slots)))
                          (old (cdr slots)))
                      (when (chunk-p-fct old)
                        (let* ((bl (chunk-back-links old))
                               (new-links (remove slot-name (gethash chunk-name2 bl))))
                          (if new-links
                              (setf (gethash chunk-name2 bl) new-links)
                            (remhash chunk-name2 bl))))))
                            
                  ;; replace all the slot values which hold chunk-name2 with chunk-name1
                  (when (hash-table-p (chunk-back-links chunk-name2))
                    (maphash (lambda (chunk slots)
                               (dolist (x slots)
                                 (fast-set-chunk-slot-value-fct chunk x chunk-name1)
                                 (dolist (notify (notify-on-the-fly-hooks))
                                   (dispatch-apply notify chunk))))
                             (chunk-back-links chunk-name2))
                    (clrhash (chunk-back-links chunk-name2)))))))))
      chunk-name1)))
```
