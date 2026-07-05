[cond](https://www.lispworks.com/documentation/HyperSpec/Body/m_cond.htm#cond) is a [[function vs macro|macro]] that evaluates a list of if-then statements. The format is as follows:
```
(cond ((if_1) (then_1))
	  ((if_2) (then_2))
	  ...)
```
Where each `if` is evaluated in order, and if that `if` returns [[t|true]], then that `then` is returned and no further statements are evaluated.