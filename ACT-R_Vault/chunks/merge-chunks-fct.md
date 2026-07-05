## Function description
Function merges two chunks 

## Code
First it gets the structure of both chunks using [[get-chunk|get-chunk-warn]], and saves both chunk representations to c1 and c2.
with (when (and c1 c2), it makes sure both chunks got retrieved correctly. After this 'when' are 2 'unless' clauses and 'chunk-name1'.
Then, it will return nil from the function if c1 and c2 are not equal according to [[chunk-equal-test]].  
If the c1 and c2 are the same object completely, the big part of code is not executed

```
(defun merge-chunks-fct (chunk-name1 chunk-name2)
  "Merge two chunks into a single representation"
  (let ((c1 (get-chunk-warn chunk-name1))
        (c2 (get-chunk-warn chunk-name2)))
    (when (and c1 c2)
      (unless (chunk-equal-test c1 c2)
        (return-from merge-chunks-fct nil))
      (unless (eq c1 c2)
        (bt:with-recursive-lock-held ((act-r-chunk-lock c1))
          (bt:with-recursive-lock-held ((act-r-chunk-lock c2))
```
if the 2 chunks were retrieved correctly and they are not the same object, the objects are held with a lock so they're not changed at the same time.

## Update parameters for c1 ([[dolist]] 1)
```          
            ;; update the parameters for c1
            (dolist (param (bt:with-lock-held (*chunk-parameters-lock*)
                             *chunk-parameters-merge-list*))
```
For each parameter from the internal list of parameters that have a merge function:
	set that parameter of c1 to... ([[aref]] means access the array in the first bracket with the index of the second)
```
              (setf (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param))
```
[[act-r-chunk-parameter-merge]]?? I can't find this macro :D (same for some of the others that start with act-r, but those I can at least guess)
```
                (case (act-r-chunk-parameter-merge param)
```
if it matched "second":
save this parameter of c2 to temporary value v and return this value, unless it is undefined in c2, in which case it returns the default parameter value for that chunk type (I think).
```
                  (:second
                   (let ((v (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
                     (if (eq v *chunk-parameter-undefined*)
                         (chunk-parameter-default param chunk-name2)
                         v)))
```
if it matched to "second-if"
do the same thing as the clause above, but the other way around? first check if it's undefined (if so set default), and then (new) if v is still nil, return the value that is the parameter of c1 instead.
```
                  (:second-if
                   (let ((v (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
                     (when (eq v *chunk-parameter-undefined*)
                       (setf v (chunk-parameter-default param chunk-name2)))
                     (if v
                         v
                       (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param)))))
```
the default case that happens if the above don't:
... I don't understand this one.
```
                  (t
                   (dispatch-apply (act-r-chunk-parameter-merge param) chunk-name1 chunk-name2)))))                
```

## (dolist 2)
Go through all parameters again
```
            (dolist (param (bt:with-lock-held (*chunk-parameters-lock*)
                             *chunk-parameters-merge-value-list*))
```
Set the value of that parameter within chunk 1 (again, [[aref]] means get from this () array the thing at this () index) to whatever the next bit is going to return
```
              (setf (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param))
```
first create temp variables c1-val and c2-val that are the values associated with chunk 1 and chunk 2
```
                (let ((c1-val (aref (act-r-chunk-parameter-values c1) (act-r-chunk-parameter-index param)))
                      (c2-val (aref (act-r-chunk-parameter-values c2) (act-r-chunk-parameter-index param))))
```
[[dispatch-apply]]  will apply a function to [[rest]] variables 
the function here is the merge value? and the variables c1-val / c2-val??
```
                  (dispatch-apply (act-r-chunk-parameter-merge-value param)
                                  (if (eq c1-val *chunk-parameter-undefined*)
                                      (chunk-parameter-default param chunk-name1)
                                    c1-val)
                                  (if (eq c2-val *chunk-parameter-undefined*)
                                      (chunk-parameter-default param chunk-name2)
                                    c2-val)))))
```

### Parameters for c1 have been updated, now do some cleanup
wow there's comments here. how nice. I wish there were more.

```
            ;; If either is immutable then the result should be as well.
            ;; Since c1 will maintain its immutability need to check if c2
            ;; is immutable and then make c1 immutable if c2 is.
            
            (when (act-r-chunk-immutable c2)
              (setf (act-r-chunk-immutable c1) t))
```

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

done :D merged.
