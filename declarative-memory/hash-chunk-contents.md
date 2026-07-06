```
;;; A function for converting a chunk to a list of its info
  
(defun hash-chunk-contents (chunk)
 (let ((c (get-chunk chunk)))
    (when c
      (bt:with-recursive-lock-held ((act-r-chunk-lock c))
        (cons (act-r-chunk-filled-slots c)
              (mapcar (lambda (x)
                        (let ((val (cdr x)))
                          (if (stringp val)
                              (string-upcase val)
                            (true-chunk-name-fct val))))
                (sort (copy-list (act-r-chunk-slot-value-lists c))
                      #'< :key (lambda (x) (act-r-slot-index (car x))))))))))
```
define function
save the chunk in variable c
when there actually is a chunk with this name, do the following:
hold the chunk in a lock
create a dotted pair with the filled slots of the chunk and:
	list of the true chunk names of all the values in 
