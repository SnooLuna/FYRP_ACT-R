---
aliases:
  - make-act-r-chunk
---
```
(defstruct act-r-chunk
  "The internal structure of a chunk"
  name base-name
  documentation
  (filled-slots 0)
  slot-value-lists
  copied-from
  merged-chunks
  parameter-values
  immutable
  not-storable
  (lock (bt:make-recursive-lock)))
```

