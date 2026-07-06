;;; Example of using the chunk-add-hook, chunk-merge-hook, retrieval-set-hook,
;;; and retrieved-chunk-hook to adjust chunk parameters after the addition/merging
;;; as well as overriding which chunk gets retrieved and recording those chunks.
;;; I've unfortunately already forgotten which way you want the activation updating
;;; to go with respect to the original and the later chunks, but hopefully there's
;;; enough detail here to let you do what you need.

;;; I found two small issues with this approach when implementing the example, one
;;; with the add hook and one with the merge hook.  There are comments in the functions
;;; used for those hooks to describe the issues.

;;; I also added a stub of a module and one buffer to use as a way to indicate when to 
;;; retrieve the second best (or other non-best), and for recording the past 
;;; retrieved chunks which seemed like it may be helpful to limit the search to find
;;; the parent chunks.  Encapsulating any needed data in a module is recommended because
;;; it then allows things to work when there are multiple models running without
;;; problems.

;;; The documentation of the hook parameters can be found in the reference manual,
;;; but the comments with them here cover most of the details.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Start with the module because that's where the chunk names from the past 
;;; retrievals are going to be stored and I'll use that in the hooks.

;;; Simple structure for the module to just hold a list of past retrievals and
;;; the flag to signal overriding the most active chunk.

(defstruct example past-chunks override)

;;; A module needs a creation function that returns an instance for
;;; the model.  In this case a simple structure, but if you prefer objects and
;;; methods you could create a class and define the subsequent functions
;;; as methods instead.

(defun create-example-module (name) ;; passed the model name
  (declare (ignore name))
  (make-example))


;;; Module should have a reset function to clear its internal information
;;; when the model gets reset, and add any chunk and types that it will
;;; be using.

(defun reset-example-module (instance)
  (setf (example-past-chunks instance) nil)
  (setf (example-override instance) nil)
  
  ;; Chunk type and chunk names used in the test module.

  (chunk-type example-request position) 
  (define-chunks first second third))


;;; Because it will have a buffer it needs a function to respond to 
;;; queries.  The query function is passed a slot and value for the
;;; query, and if that slot value pair is true, then return any true
;;; value, otherwise return nil.
;;; This example is only going to respond to the state queries (since that
;;; is expected for a module) and free will be true if there is no pending
;;; override and busy will be true if there is.  Not sure that makes, sense
;;; for the operation, but is a simple example.  

(defun query-example-module (instance buffer slot value)
  ;; don't need to case on the buffer since
  ;; the module only has one, but if you wanted more buffers
  ;; with different states you'd need to check that.
  
  (cond ((eq slot 'state) 
         (case value
           (free (null (example-override instance)))
           (busy (example-override instance))
           (t t))) ;; assume any other state value is true
        
        ;; There could be other slots that are available to
        ;; query, perhaps the specific value of the override.
        ;; If desired, those would need to be specified in the
        ;; buffer definition in the module definition to be
        ;; usable.
        
        (t ;; As a safety case, but should never get here 
           ;; since only valid queries get to the module.
         
         (model-warning "Invalid ~a buffer query with slot ~a and value ~a" buffer slot value))))


;;; The buffer request function for the module. The only action it will
;;; perform is to record which activation position to retrieve when overriding
;;; the retrieval of a chunk.  Probably need something smarter to provide the
;;; details for searching through the matching chunks to find the right target,
;;; or perhaps it could all be done without the buffer and handled directly 
;;; in the hook functions.

(defun request-example-module (instance buffer-name spec)
  (declare (ignore buffer-name))
  ;; Not checking the buffer since the module only has one.
  ;; spec is a chunk-spec (chunk specification details in the manual) that
  ;; describes the request that was made.  It's basically a set of 
  ;; modifier, slot, value lists (referred to as slot-specs) as provided 
  ;; in the production, and there are accessor functions for getting the
  ;; individual components from the chunk-spec and slot-spec.
  
  ;; I'm going to make some assumptions about the request for simplicity:
  ;; - there's only one slot in the request
  ;; - if it's not named position then ignore it
  ;; - there are no modifiers on the slot
  
  (let* ((specs (chunk-spec-slot-spec spec)) ;; the list of all slot-specs
         (first-spec (first specs)) ;; the first slot-spec, since assuming only 1
         (slot (slot-spec-slot first-spec)) 
         (value (slot-spec-value first-spec)))
    (when (eq slot 'position)
      (setf (example-override instance) value))))

  
;;; This example module doesn't have any parameters, so don't need a parameter
;;; function.  However, a nice feature for an extension that modifies the operation
;;; via hooks is to have an "enable" parameter which then sets/removes the hook 
;;; parameters automatically with that single parameter instead of requiring the
;;; model to have the individual settings for all the necessary hooks.
;;; You can look at the extras/spacing-effect/spacing-effect.lisp as an example
;;; of a module that uses the bl-hook and has an enable parameter for setting and
;;; disabling it, and also monitors the parameter to make sure the user doesn't
;;; change it when the extension is enabled and could break the operation of the module.


;;; Given those functions, here's the definition of the module.

(define-module :example ;; module name
  (example)             ;; list of buffer names
  nil                   ;; the list of parameters for the module
  :version "0.1a"       ;; all modules should have a version and doc string
  :documentation "example for using declartive hooks" 
  
  ;; speicfy the functions to implement the module
  :creation create-example-module
  :reset reset-example-module
  :query query-example-module
  :request request-example-module)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Here are the example hook functions for adjusting chunk parameters.
;;;
;;; These are the settings that will be required in the model for the hooks in
;;; in this example to be used:
;;;
;;; (sgp :retrieved-chunk-hook chunk-retrieved
;;;      :retrieval-set-hook override-retrieval
;;;      :chunk-add-hook chunk-added
;;;      :chunk-merge-hook chunk-merged)


(defun chunk-retrieved (name)
  ;; whenever a chunk is retrieved add it to the
  ;; front of the list in the :example module
  
  (when name ;; it's nil if there's a retrieval failure
    (push name (example-past-chunks (get-module :example)))))


(defun override-retrieval (chunks) ;; the list of chunks where the first
                                   ;; has highest activation and the rest
                                   ;; are in no particular order.
  
  ;; If the module has an override value then this will return 
  ;; the chunk from that position in the sorted activation list
  ;; and clear the override value.
  
  (let ((module (get-module :example)))
    
    (when (example-override module)
      
      ;; sort the list by the activation they had during the retrieval request

      (let* ((in-order (sort (mapcar (lambda (x)
                                       (cons x (chunk-retrieval-activation x)))
                               chunks)
                             #'>
                             :key 'cdr))
             
             ;; Just use the chunk from the position specified in
             ;; the request to the example buffer.
             
             (new-item (case (example-override module)
                         (first (first in-order))
                         (second (second in-order))
                         (third (third in-order)))))
        
        
        (model-output "Chunk ~s had the highest activation but retrieving the ~s highest chunk instead." (first (first in-order)) (example-override module))
        
        (setf (example-override module) nil)
        
        (when new-item
          
          ;; need to return a list of the chunk name and the duration time for the
          ;; retrieval which will need to be computed from the activation: F*e^-(f*A)
          
          (let ((lf (get-parameter-value :lf)) ;; F
                (le (get-parameter-value :le))) ;; f
            
            (list (car new-item) (* lf (exp (- (* le (cdr new-item))))))))))))
                

;;; Both of these hooks get called after the declarative module
;;; has adjusted all of the parameter values normally.

(defun chunk-added (chunk)
  
  ;; Because the chunk-add-hook gets called for ALL additions, not just those
  ;; from a buffer clearing, that includes those in any add-dm calls in the model.
  ;; The simple solution used here is to only check things after time 0, but
  ;; if a modeler is explicitly adding things to memory after initiailzation
  ;; then it may be a little trickier to handle, and require more logic to
  ;; do the "right" thing.

  
  ;; For the example, when a chunk is added to DM other than at time 0, update 
  ;; the history of that chunk to have the same history of the last chunk that
  ;; was retrieved from memory along with its new reference.
  
  
  (when (> (get-time) 0)
    
    (when (get-parameter-value :bll) ;; if base-level learning isn't
                                     ;; turned on there's no history to adjust
      
      (let ((module (get-module :example)))
        
        ;; when there was a previously retrieved chunk
        
        (when (example-past-chunks module)
          
          (let ((old-chunk (first (example-past-chunks module)))) ;; most recently retrieved
            
            
            (model-output "Chunk ~a being added to DM and getting starting history from chunk ~a." chunk old-chunk)
            
            ;; use the sdp command to get and set the appropriate
            ;; parameters for the chunks.
            ;; One thing to be careful about is the value of the
            ;; :ol (optimized learning) parameter because there are
            ;; different underlying parameters based on how it is
            ;; set.
            
            (no-output ;; suppress the sdp command's typical output
             
             (let ((ol (get-parameter-value :ol))
                   (old-creation (caar (sdp-fct (list old-chunk :creation-time))))
                   (old-count (caar (sdp-fct (list old-chunk :reference-count))))
                   (old-references (caar (sdp-fct (list old-chunk :reference-list)))))
               
               ;; all :ol activation methods use creation time
               
               (sdp-fct (list chunk :creation-time old-creation))
               
               ;; do the right thing for count/references based on :ol
               
               (cond ((null ol) ;; there's only a list of references 
                                ;; so just add the current time in seconds 
                      (sdp-fct (list chunk :reference-list (cons (mp-time) old-references))))
                     
                     ((numberp ol) ;; both a count and references
                      ;; add the current time 
                      ;; and increment the reference count
                      (sdp-fct (list chunk :reference-list (cons (mp-time) old-references)
                                     :reference-count (incf old-count))))
                     
                     (t ;; only a count
                      (sdp-fct (list chunk :reference-count (incf old-count)))))))))))))




(defun chunk-merged (chunk)
  
  ;; There's a slight complication with this because an efficiency update
  ;; to ACT-R changed how the buffers handle a chunk.  Now, by default each
  ;; of the buffers hold a special chunk with fixed name that gets used for
  ;; all chunks put into that buffer.
  ;; That name can't be merged with the name of the chunk in DM since
  ;; it will be reused by the buffer.  Thus, the name passed to this function
  ;; may not be a reference to the original chunk that it was merged
  ;; with in DM (which usually happens during merging).  There are two ways
  ;; around this.  The first would be to turn off that efficiency update.
  ;; That would require calling the buffer-requires-copies function in the
  ;; model definition for each of the buffers that are used by the model.
  ;; The other, which is used here, is to assume that the chunks in DM are
  ;; unique and then search for the chunk in DM that matches the chunk passed
  ;; to this function.  The only way that uniqueness assumption would be 
  ;; violated is through calls to add-dm with identical definitions, and 
  ;; doing that in a model with base-level learning on creates a problem for
  ;; activiation learning in general since it may result in references 
  ;; going to different chunks at different times.

  
  ;; For this example, when a chunk gets merged, if it's a match to any of
  ;; the previously retrieved chunks, it's going to remove the reference from
  ;; the chunk in DM with which it was merged.
  
  (when (get-parameter-value :bll) ;; if base-level learning isn't
                                   ;; turned on there's no information to adjust
      
    (let ((module (get-module :example)))
        
      ;; when there was a previously retrieved chunk
        
      (when (example-past-chunks module)
        
        ;; Find-matching-chunks will search a set of chunks to find those that
        ;; are exact matches to the chunk-spec provided.
        ;; So this will test if any of the past retrievals match the chunk that
        ;; was merged into memory.
        
        (when (find-matching-chunks (chunk-name-to-chunk-spec chunk)
                                    :chunks (example-past-chunks module))
          
          ;; Now search DM to find the chunk that received the update using
          ;; the sdm function to do so.
          ;; That's not really necessary since the name is in the list
          ;; of matching-chunks found above, but want to provide the 
          ;; more general example of finding it which may be more useful
          ;; for what you need.
          
          (let ((original (first (no-output (sdm-fct (list chunk)))))) ;; should only be one
            
            (when original ;; should always find one since there was a merging, but I like to test anyway
              
              (model-output "Chunk ~a being merged into DM but eliminating the reference being added to chunk ~a." chunk original)
              
              ;; use the sdp command to remove the reference and/or decrease count
            
              (no-output ;; suppress the sdp command's typical output
             
               (let ((ol (get-parameter-value :ol))
                     (count (caar (sdp-fct (list original :reference-count))))
                     (references (caar (sdp-fct (list original :reference-list)))))
               
               ;; do the right thing for count/references based on :ol
               
               (cond ((null ol) ;; only references
                      (sdp-fct (list original :reference-list (cdr references))))
                     ((numberp ol) ;; both a count and references
                      (sdp-fct (list original :reference-list (cdr references)
                                     :reference-count (decf count))))
                     (t ;; only a count
                      (sdp-fct (list original :reference-count (decf count))))))))))))))
  
  