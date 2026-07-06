## Function description
This function hashes a chunk so it can be stored in the hash tables used throughout ACT-R. For example, all chunks in a model are stored in one big hash table that can be referenced when the contents of the chunk are needed when only the name is known. 
# Code
```
;;; A function for converting a chunk to a list of its info
  
(defun hash-chunk-contents (chunk)
```
The local variable `c` is defined and the chunk is stored in that variable. Then, when c exists (and thus is not [[nil]]), the chunk is locked so we can safely access the contents.
```
 (let ((c (get-chunk chunk)))
    (when c
      (bt:with-recursive-lock-held ((act-r-chunk-lock c))
```
Use [[cons]] to create a dotted pair with the names of the filled slots of the chunk as the [[car]] and a list of the 'true chunk names' or uppercase versions of all the slot values as the [[cdr]].
```
        (cons (act-r-chunk-filled-slots c)
              (mapcar (lambda (x)
                        (let ((val (cdr x)))
                          (if (stringp val)
                              (string-upcase val)
                            (true-chunk-name-fct val))))
                (sort (copy-list (act-r-chunk-slot-value-lists c))
                      #'< :key (lambda (x) (act-r-slot-index (car x))))))))))
```
