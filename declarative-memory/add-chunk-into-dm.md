## Function description

## Code
```
;; add-chunk-into-dm
;;;
;;; works like merge-chunk-into-dm but without doing any merging i.e. it
;;; makes the chunk part of dm and sets it's initial parameters regardless
;;; of whether it is a perfect match to an existing member
;;;
  
(defun add-chunk-into-dm (dm chunk &optional slot-key)
  (let (sa cah)
    (bt:with-lock-held ((dm-param-lock dm))
      (setf sa (dm-sa dm)
        cah (dm-chunk-add-hook dm)))
    ;; make it immutable
    (make-chunk-immutable chunk)
    (bt:with-lock-held ((dm-chunk-lock dm))
      (aif (assoc (chunk-slots-vector chunk) (dm-chunks dm))
           (push chunk (cdr it))
           (push (cons (chunk-slots-vector chunk) (list chunk)) (dm-chunks dm)))
      ;; Add it to the merge table
      (let ((key (aif slot-key it (hash-chunk-contents chunk))))
        (setf (chunk-fast-merge-key chunk) key)
        (setf (gethash key (dm-chunk-hash-table dm)) chunk)))
    ;; set the parameters
    (setf (chunk-in-dm chunk) t)
    (setf (chunk-creation-time chunk) (mp-time-ms))
    (setf (chunk-reference-list chunk) (list (mp-time-ms)))
    (setf (chunk-reference-count chunk) 1)
    ;; mark it as invalid for a buffer set now
    (setf (chunk-buffer-set-invalid chunk) t)
    ;; when spreading activation is on set the fan-out and fan-in values
    (when sa
      ;; Increment its fan-out for itself
      (incf (chunk-fan-out chunk))
      ;; set the fan-in values
      (let ((new-fans (mapcan (lambda (slot)
                                (let ((val (fast-chunk-slot-value-fct chunk slot)))
                                  (when (chunk-p-fct val)
                                    (list val))))
                        (chunk-filled-slots-list-fct chunk))))
        (dolist (j new-fans)
          (incf (chunk-fan-out j)))
        (setf (chunk-fan-in chunk)
          (mapcar (lambda (x) (cons x (count x new-fans))) (remove-duplicates new-fans))))
      (aif (assoc chunk (chunk-fan-in chunk))
           (incf (cdr it))
           (push (cons chunk 1) (chunk-fan-in chunk))))
    (when (car cah)
      (dolist (x cah)
        (dispatch-apply x chunk)))))
```