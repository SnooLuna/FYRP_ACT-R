```
(defstruct act-r-chunk-spec
  "The internal structure of a chunk-spec"
  (filled-slots 0)
  (empty-slots 0)
  (request-param-slots 0)
  (duplicate-slots 0)
  (equal-slots 0)
  (negated-slots 0)
  (relative-slots 0)
  variables
  slot-vars
  dependencies
  slots
  testable-slots
  slot-names)
```