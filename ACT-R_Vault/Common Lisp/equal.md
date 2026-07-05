[equal](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) is a function that returns true if the two objects passed to it are equal. 
From the documentation:

> **[_Symbols_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_s.htm#symbol), [_Numbers_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_n.htm#number), and [_Characters_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#character)**
> 
> [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) is [_true_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_t.htm#true) of two [_objects_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_o.htm#object) if they are [_symbols_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_s.htm#symbol) that are [**eq**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eq.htm#eq), if they are [_numbers_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_n.htm#number) that are [**eql**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eql.htm#eql), or if they are [_characters_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#character) that are [**eql**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eql.htm#eql).
> 
> **[_Conses_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#cons)**
> 
> For [_conses_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#cons), [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) is defined recursively as the two [_cars_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#car) being [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) and the two [_cdrs_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_c.htm#cdr) being [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal).
> 
> **[_Arrays_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_a.htm#array)**
> 
> Two [_arrays_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_a.htm#array) are [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) only if they are [**eq**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eq.htm#eq), with one exception: [_strings_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_s.htm#string) and [_bit vectors_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_b.htm#bit_vector) are compared element-by-element (using [**eql**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eql.htm#eql)). If either _x_ or _y_ has a [_fill pointer_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_f.htm#fill_pointer), the [_fill pointer_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_f.htm#fill_pointer) limits the number of elements examined by [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal). Uppercase and lowercase letters in [_strings_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_s.htm#string) are considered by [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) to be different.
> 
> **[_Pathnames_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_p.htm#pathname)**
> 
> Two [_pathnames_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_p.htm#pathname) are [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) if and only if all the corresponding components (host, device, and so on) are equivalent. Whether or not uppercase and lowercase letters are considered equivalent in [_strings_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_s.htm#string) appearing in components is [_implementation-dependent_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_i.htm#implementation-dependent). [_pathnames_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_p.htm#pathname) that are [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) should be functionally equivalent.
> 
> **Other (Structures, hash-tables, instances, ...)**
> 
> Two other [_objects_](https://www.lispworks.com/documentation/HyperSpec/Body/26_glo_o.htm#object) are [**equal**](https://www.lispworks.com/documentation/HyperSpec/Body/f_equal.htm#equal) only if they are [**eq**](https://www.lispworks.com/documentation/HyperSpec/Body/f_eq.htm#eq).

used by [[equalp]]