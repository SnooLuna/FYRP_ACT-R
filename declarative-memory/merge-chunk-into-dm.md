## Function description
This function is called to merge a chunk into the declarative memory, like when a buffer is cleared or this action is explicitly called. The function requires the declarative memory of the model, the buffer that the chunk is currently in and the chunk itself to be passed to the function. Additional parameters can also be specified, including the boolean that when set to true, will ensure no stuffing event is scheduled for this action.

The actual merging of the chunks is done with [[merge-chunks-fct]]. The function this page is for, handles the logistics around it, like reading the hashmap, scheduling an event, checking whether it needs to be merged or added, etc.

The function has the following comment: 
```
;;; Merge-chunk-into-dm
;;;
;;; This function will be called automatically each time a buffer is cleared.
;;;
;;; The parameters are an instance of the module, the name of the buffer that
;;; was cleared, and the name of the chunk that was in the buffer.
;;;
;;; This module adds that chunk to declarative memory and increments its
;;; reference count. If a matching chunk already exists in declarative memory,
;;; then those chunks are merged together. If this is the first occurrence of
;;; the chunk, then its initial parameters are set accordingly.
```

## Code
Create new function and its accepted arguments.
The three main arguments that are accepted are: `dm`, `buffer` and `chunk`. Besides these, some optional further arguments can be passed, among which is a setting for ignoring the stuffing of the buffers, which is set to [[nil|false]] by default
```
(defun merge-chunk-into-dm (dm buffer chunk &optional (ignore-stuffing nil))
```
Make three local variables, `stuff`, `cmh`, and `ignore`:
```
  (let (stuff cmh ignore)
```
The parameters of the declarative memory are locked, so they cannot be changed or accessed, and the stuff, chunk merge hook and ignore buffers are accessed and saved in the newly created variables.
```
    (bt:with-lock-held ((dm-param-lock dm))
      (setf stuff (dm-stuff dm)
        cmh (dm-chunk-merge-hook dm)
        ignore (dm-ignore-buffers dm)))
```
If the buffer is in the list of dm-ignore-buffers, just skip and the function is done, we don't need to merge anything from this buffer into the dm.
```
    (unless (find buffer ignore)
```

The next part schedules an event for stuffing the declarative memory - The code does the following:
when the current buffer is the retrieval buffer, and the `ignore-stuffing` parameter is not [[t|true]], and the `stuff` parameter is not [[nil]]:
	hold the state of the declarative memory in a lock, and unless there already is a stuffing event set, set/schedule the event to one called `check-declarative-stuffing` with the parameters listed underneath.
```
      (when (and (eq buffer 'retrieval) (not ignore-stuffing) stuff)
        (bt:with-lock-held ((dm-state-lock dm))
          (unless (dm-stuff-event dm)
            (setf (dm-stuff-event dm)
              (schedule-event-now 'check-declarative-stuffing
                                  :module 'declarative
                                  :destination 'declarative
                                  :output 'low
                                  :priority :min
                                  :maintenance t)))))
```
Then, having finished the entire event scheduling list, we move on to actually merging the chunk into the declarative memory.

First, we declare two local variables, `key` and `existing`. 
`key` is defined as the result of ([[hash-chunk-contents]] chunk), which means the key represents the entire contents of the chunk given to this function.
`existing` is defined to check if this chunk already exists in the declarative memory. It uses the function [[gethash]] to get the potential entry in the declarative memory already associated with this key. While doing this, it locks the chunks of the declarative memory to make sure nothing is changed during the process.
```
      (let* ((key (hash-chunk-contents chunk))
             (existing 
	             (gethash key 
		             (bt:with-lock-held 
			             ((dm-chunk-lock dm)) 
			             (dm-chunk-hash-table dm)))))
```
Now that we know whether this chunk already exists in declarative memory or not, we can finally merge it.

If the chunk already exists in the dm, we execute two processes using [[progn]]. The first merges the chunk with the chunk that already exists in the declarative memory. The second handles any chunk-merge-hooks (cmh) that have been declared. When there are things specified in the cmh, each is applied to the chunk using [[dolist]] and [[dispatch-apply]].
```
        (if existing
            (progn
              (merge-chunks-fct existing chunk)  ;; merging functions handle params
              (when (car cmh)
                (dolist (x cmh)
                  (dispatch-apply x chunk))))
```
if the chunk does not yet exist in the declarative memory, it needs to be added into there. 
If the chunk is not directly storable, this is done with an extra step through copying the chunk, and otherwise it is directly passed to [[add-chunk-into-dm]].
```          
          (if (chunk-not-storable chunk)
              (add-chunk-into-dm dm (copy-chunk-fct chunk) key)
            (add-chunk-into-dm dm chunk key)))))))
```
