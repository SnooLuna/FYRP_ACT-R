couple different functions, just putting them here so I remember they exist:
```
(defmacro chunk-copied-from (chunk-name)
  "Return the name of the chunk from which the provided chunk was copied"
  `(chunk-copied-from-fct ',chunk-name))
  
(defun chunk-copied-from-fct (chunk-name)
  "Return the name of the chunk from which the provided chunk was copied"
  (let ((chunk (get-chunk-warn chunk-name)))
    (when chunk
      (let ((copied-from (bt:with-recursive-lock-held ((act-r-chunk-lock chunk)) (act-r-chunk-copied-from chunk))))
        (values
         (when (and copied-from (chunk-p-fct copied-from) (equal-chunks-fct chunk-name copied-from))
           copied-from)
         copied-from)))))
  
(defun external-chunk-copied-from (chunk-name)
  (chunk-copied-from-fct (string->name chunk-name)))
  

(add-act-r-command "chunk-copied-from" 'external-chunk-copied-from "Returns the name of the chunk from which the given chunk was copied. Params: chunk-name.")
```