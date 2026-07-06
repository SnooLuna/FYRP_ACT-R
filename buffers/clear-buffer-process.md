# Function description

# Code
```
(defun clear-buffer-process (buffer bn)
  "This is what happens when the buffer clears.  Done separately because may need to be done from inside something that's already locked and don't want a recursive lock."
  ;; clear all the flags
  (setf (act-r-buffer-flags buffer) nil)
  (let ((chunk (act-r-buffer-chunk buffer)))
    (when chunk
      ;; remove the chunk
      (setf (act-r-buffer-chunk buffer) nil)
      ;; mark it invalid for a buffer-set and take it out of this one if needed
      (setf (chunk-buffer-set-invalid chunk) t)
      (when (act-r-buffer-multi buffer)
        (remhash chunk (act-r-buffer-chunk-set buffer)))
      ;; Pass it off to any module that wants to know
      (dolist (module (notified-modules))
        (notify-module module bn chunk)))
    chunk))
```