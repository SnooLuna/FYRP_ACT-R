---
tags:
  - big
---
called by the macro "copy-chunk":
```
(defmacro copy-chunk (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
  `(copy-chunk-fct ',chunk-name))
```


```
(defun copy-chunk-fct (chunk-name)
  "Create a new chunk which is a copy of the given chunk"
  (let ((chunk (get-chunk-warn chunk-name)))
    (when chunk
      (bt:with-recursive-lock-held ((act-r-chunk-lock chunk))
        (when (use-short-copy-names)
          (unless (act-r-chunk-base-name chunk)
            (setf (act-r-chunk-base-name chunk) (concatenate 'string (symbol-name chunk-name) "-"))))
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
          ;; Create the back links as needed
          (when (update-chunks-on-the-fly)
            (bt:with-recursive-lock-held ((act-r-model-chunk-lock (current-model-struct)))
              (dolist (slot (act-r-chunk-slot-value-lists chunk))
                (let ((slot-name (act-r-slot-name (car slot)))
                      (old (cdr slot)))
                  (when (chunk-p-fct old)
                    (let ((bl (chunk-back-links old)))
                      (if (hash-table-p bl)
                          (push slot-name (gethash new-name bl))
                        (let ((ht (make-hash-table)))
                          (setf (gethash new-name ht) (list slot-name))
                          (setf (chunk-back-links old) ht)))))))))
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
          ;; note the original
          (setf (act-r-chunk-copied-from new-chunk) chunk-name)
          ;; Put it into the main table
          (let ((model (current-model-struct)))
            (bt:with-recursive-lock-held ((act-r-model-chunk-lock model))
              (setf (gethash new-name (act-r-model-chunks-table model)) new-chunk)))
          new-name)))))
```