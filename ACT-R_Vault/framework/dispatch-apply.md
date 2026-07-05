define a function called dispatch-apply with the variables fct, and rest. it returns t or nil.
it applies the function to the variables in rest
*fct is short for function **(NOT FACT)*

```
(defun dispatch-apply (fct &rest rest)
```
conditional (switch) start
```
  (cond ((stringp fct)
```
if fct is a string: save tmp var results, containing the results of the function, 
```
         (let ((results (multiple-value-list (apply 'evaluate-act-r-command (cons fct rest)))))
           (if (first results)
               (values-list (rest results))
             (print-warning "Error ~s while attempting to evaluate the form (~s ~{~s~^ ~})" (second results) fct rest))))
```
if fct is a function: [[apply]] the function to the rest
```
        ((functionp fct)
         (apply fct rest))
```
if fct is a symbol and fct is [[fbound]]: [[apply]] the function the symbol is bound to to the rest
```
        ((and (symbolp fct) (fboundp fct))
         (apply fct rest))
```
otherwise print a warning
```
        (t
         (print-warning "Function ~s passed to dispatch-apply is not a local function or valid remote command string" fct))))
```
