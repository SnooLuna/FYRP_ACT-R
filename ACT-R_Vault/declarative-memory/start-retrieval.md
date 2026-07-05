


```
;;; Start-retrieval
;;;
;;; This function is called to actually attempt a retrieval.
;;;
;;; The parameters it receives are an instance of the module and the
;;; chunk-spec of the request.
;;;
;;; It either schedules the setting of the retrieval buffer or indicationof
;;; an error depending on whether or not it finds a chunk that matches the
;;; request.
;;;
;;; There are several parameters that determine how the "best" matching chunk
;;; is selected and how long that action will take.

  
(defun start-retrieval (dm request)
  (let (esc rt rrh sact act er set-hook
            mp offsets blc bll ol act-scale
            sa spreading-hook w-hook sji-hook mas nsji
            pm-hook ms md sim-hook cache-sim-hook
            noise-hook ans lf le bl-hook)
    (bt:with-lock-held ((dm-state-lock dm))
      (when (dm-stuff-event dm)
        (delete-event (dm-stuff-event dm))
        (setf (dm-stuff-event dm) nil)))
    (bt:with-lock-held ((dm-param-lock dm))
      (setf
       act (dm-act dm)
       rt (dm-rt dm)
       sact (dm-sact dm)
       mp (dm-mp dm)
       esc (dm-esc dm)
       offsets (dm-offsets dm)
       blc (dm-blc dm)
       bll (dm-bll dm)
       ol (dm-ol dm)
       act-scale (dm-act-scale dm)  
       sa (dm-sa dm)
       spreading-hook (dm-spreading-hook dm)
       w-hook (dm-w-hook dm)
       sji-hook (dm-sji-hook dm)
       mas (dm-mas dm)
       nsji (dm-nsji dm)
       pm-hook (dm-partial-matching-hook dm)
       ms (dm-ms dm)
       md (dm-md dm)
       sim-hook (dm-sim-hook dm)
       cache-sim-hook (dm-cache-sim-hook-results dm)
       noise-hook (dm-noise-hook dm)
       ans (dm-ans dm)
       rrh (dm-retrieval-request-hook dm)
       er (dm-er dm)
       set-hook (dm-retrieval-set-hook dm)
       lf (dm-lf dm)
       le (dm-le dm)
       bl-hook (dm-bl-hook dm)))
    (when rrh
      (let ((id (chunk-spec-to-id request)))
        (dolist (x rrh)
          (dispatch-apply x id))
        (release-chunk-spec-id id)))
    (when sact
      (bt:with-lock-held ((dm-state-lock dm))
        (setf (dm-current-trace dm) (make-sact-trace :esc esc))
        (setf (gethash (mp-time-ms) (dm-trace-table dm)) (dm-current-trace dm))))
    (let* ((last-request (make-last-request :time (mp-time-ms) :spec request :rt rt))
           (filled (chunk-spec-filled-slots request))
           (empty (chunk-spec-empty-slots request))
           (chunk-list (mapcan (lambda (x)
                                 (if (slots-vector-match-signature (car x) filled empty)
                                     (copy-list (cdr x))
                                   nil))
                         (bt:with-lock-held ((dm-chunk-lock dm)) (dm-chunks dm))))
           )
    (flet ((invalid (reason warnings)
                      (bt:with-lock-held ((dm-state-lock dm))
                        (setf (dm-busy dm) nil)
                        (setf (last-request-invalid last-request) reason)
                        (setf (dm-last-request dm) last-request)
                        )
                      (dolist (x warnings)
                        (print-warning x))
                      (return-from start-retrieval)))
      (let ((requested-slots (chunk-spec-slots request)))
        (when (member :recently-retrieved requested-slots)
          (let ((recent (chunk-spec-slot-spec request :recently-retrieved)))
            (cond ((> (length recent) 1)
                   (invalid :too-many '("Invalid retrieval request." ":recently-retrieved parameter used more than once.")))
                  ((not (or (eq '- (caar recent)) (eq '= (caar recent))))
                   (invalid :bad-modifier '("Invalid retrieval request." ":recently-retrieved parameter's modifier can only be = or -.")))
                  ((not (or (eq t (third (car recent)))
                            (eq nil (third (car recent)))
                            (and (eq 'reset (third (car recent)))
                                 (eq '= (caar recent)))))
                   (invalid :bad-value '("Invalid retrieval request." ":recently-retrieved parameter's value can only be t, nil, or reset.")))
                  (t ;; it's a valid value for recently-retrieved
                   (if (eq 'reset (third (car recent)))
                       (bt:with-lock-held ((dm-state-lock dm))
                         (setf (dm-finsts dm) nil))
                     (let ((finsts (remove-old-dm-finsts dm)))
                       (cond ((or (and (eq t (third (car recent)))   ;; = request t
                                       (eq (caar recent) '=))
                                  (and (null (third (car recent)))   ;; - request nil
                                       (eq (caar recent) '-)))
                              ;; only those chunks marked are available
                              (setf chunk-list (intersection (mapcar 'car finsts) chunk-list))
                              ;; save that info for whynot
                              (setf (last-request-finst last-request) :marked)
                              (setf (last-request-finst-chunks last-request) chunk-list)
                              (when sact
                                (bt:with-lock-held ((dm-state-lock dm))
                                  (setf (sact-trace-only-recent (dm-current-trace dm)) t)
                                  (setf (sact-trace-recents (dm-current-trace dm)) chunk-list)))
                              (when (dm-act-level act 'high)
                                (model-output "Only recently retrieved chunks: ~s" chunk-list)))
                             (t
                              ;; simply remove the marked items
                              ;; may be "faster" to do this later
                              ;; once the set is trimed elsewise, but
                              ;; for now keep things simple
                              ;; use the if on sact for locking
                              ;; purposes to avoid having multiple
                              ;; lock holding (or the previous version that
                              ;; acquired the lock and then released later)
                              (if sact
                                  (bt:with-lock-held ((dm-state-lock dm))
                                    (setf (sact-trace-remove-recent (dm-current-trace dm)) t)
                                    (when (dm-act-level act 'high)
                                      (model-output "Removing recently retrieved chunks:"))
                                    (setf (last-request-finst last-request) :unmarked)
                                    (setf chunk-list
                                      (remove-if (lambda (x)
                                                   (when (member x finsts :key 'car :test 'eq-chunks-fct)
                                                     (push-last x (sact-trace-recents (dm-current-trace dm)))
                                                     (when (dm-act-level act 'high)
                                                       (model-output "~s" x))
                                                     (push x (last-request-finst-chunks last-request))
                                                     t))
                                                 chunk-list)))
                                (progn
                                  (when (dm-act-level act 'high)
                                    (model-output "Removing recently retrieved chunks:"))
                                  (setf (last-request-finst last-request) :unmarked)
                                  (setf chunk-list
                                    (remove-if (lambda (x)
                                                 (when (member x finsts :key 'car :test 'eq-chunks-fct)
                                                   (when (dm-act-level act 'high)
                                                     (model-output "~s" x))
                                                   (push x (last-request-finst-chunks last-request))
                                                   t))
                                               chunk-list))))
                              ))))))))
        (when (member :lf-value requested-slots)
          (let ((value (chunk-spec-slot-spec request :lf-value)))
            (cond ((> (length value) 1)
                   (invalid :lf-multi '("Invalid retrieval request." ":lf-value parameter used more than once.")))
                  ((not (eq '= (caar value)))
                   (invalid :lf-modifier '("Invalid retrieval request." ":lf-value parameter's modifier can only be =.")))
                  ((not (nonneg (third (car value))))
                   (invalid :lf-not-nonneg '("Invalid retrieval request." ":lf-value parameter's value must be a nonnegative number.")))
                  (t ;; it's a valid request
                   (setf lf (third (car value)))))))
        (when (member :ans-value requested-slots)
          (let ((value (chunk-spec-slot-spec request :ans-value)))
            (cond ((> (length value) 1)
                   (invalid :ans-multi '("Invalid retrieval request." ":ans-value parameter used more than once.")))
                  ((not (eq '= (caar value)))
                   (invalid :ans-modifier '("Invalid retrieval request." ":ans-value parameter's modifier can only be =.")))
                  ((not (posnumornil (third (car value))))
                   (invalid :ans-not-num '("Invalid retrieval request." ":ans-value parameter's value can only be nil or a positive number.")))
                  (t ;; it's a valid request
                   (setf ans (third (car value)))))))
        (when (member :bll-value requested-slots)
          (let ((bll-value (chunk-spec-slot-spec request :bll-value)))
            (cond ((> (length bll-value) 1)
                   (invalid :bll-multi '("Invalid retrieval request." ":bll-value parameter used more than once.")))
                  ((not (eq '= (caar bll-value)))
                   (invalid :bll-modifier '("Invalid retrieval request." ":bll-value parameter's modifier can only be =.")))
                  ((not (posnumornil (third (car bll-value))))
                   (invalid :bll-not-num '("Invalid retrieval request." ":bll-value parameter's value can only be nil or a positive number.")))
                  (t ;; it's a valid request
                   (setf bll (third (car bll-value)))))))
        (when (member :mas-value requested-slots)
          (let ((mas-value (chunk-spec-slot-spec request :mas-value)))
            (cond ((> (length mas-value) 1)
                   (invalid :mas-multi '("Invalid retrieval request." ":mas-value parameter used more than once.")))
                  ((not (eq '= (caar mas-value)))
                   (invalid :mas-modifier '("Invalid retrieval request." ":mas-value parameter's modifier can only be =.")))
                  ((not (numornil (third (car mas-value))))
                   (invalid :mas-not-num '("Invalid retrieval request." ":mas-value parameter's value can only be nil or a number.")))
                  (t ;; it's a valid request
                   (setf mas (third (car mas-value)))
                   (setf sa mas)))))
        (when (member :mp-value requested-slots)
          (let ((mp-value (chunk-spec-slot-spec request :mp-value)))
            (cond ((> (length mp-value) 1)
                   (invalid :mp-multi '("Invalid retrieval request." ":mp-value parameter used more than once.")))
                  ((not (eq '= (caar mp-value)))
                   (invalid :mp-modifier '("Invalid retrieval request." ":mp-value parameter's modifier can only be =.")))
                  ((not (numornil (third (car mp-value))))
                   (invalid :mp-not-num '("Invalid retrieval request." ":mp-value parameter's value can only be nil or a number.")))
                  (t ;; it's a valid request
                   (setf mp (third (car mp-value)))))))
        (when (member :rt-value requested-slots)
          (let ((rt-value (chunk-spec-slot-spec request :rt-value)))
            (cond ((> (length rt-value) 1)
                   (invalid :rt-multi '("Invalid retrieval request." ":rt-value parameter used more than once.")))
                  ((not (eq '= (caar rt-value)))
                   (invalid :rt-modifier '("Invalid retrieval request." ":rt-value parameter's modifier can only be =.")))
                  ((not (numberp (third (car rt-value))))
                   (invalid :rt-not-num '("Invalid retrieval request." ":rt-value parameter's value must be a number.")))
                  (t ;; it's a valid request
                   (setf rt (third (car rt-value))))))))
      (let ((best-val nil)
            (best nil)
            (return-val nil)
            (chunk-set
             (cond ((or (null esc) (null mp)) ;; exact matches only
                    ;; do them individually for tracing purposes
                    (if sact
                        (bt:with-lock-held ((dm-state-lock dm))
                          (let ((found nil))
                            (dolist (name chunk-list found)
                              (cond ((match-chunk-spec-p name request)
                                     (push-last name (sact-trace-matches (dm-current-trace dm)))
                                     (when (dm-act-level act 'medium)
                                       (model-output "Chunk ~s matches" name))
                                     (push-last name found))
                                    (t
                                     (push-last name (sact-trace-no-matches (dm-current-trace dm)))
                                     (when (dm-act-level act 'high)
                                       (model-output "Chunk ~s does not match" name)))))))
                      (let ((found nil))
                        (dolist (name chunk-list found)
                          (cond ((match-chunk-spec-p name request)
                                 (when (dm-act-level act 'medium)
                                   (model-output "Chunk ~s matches" name))
                                 (push-last name found))
                                (t
                                 (when (dm-act-level act 'high)
                                   (model-output "Chunk ~s does not match" name))))))))
                   (t ;; partial matching
                      ;; everything that fits the general pattern:
                      ;; filled and empty slots (already handled)
                      ;; also test the inequalities >, <, >=, and <=
                    (let* ((extra-spec (mapcan (lambda (x)
                                                 (unless (or (eq (car x) '=) (eq (car x) '-) (keywordp (second x)))
                                                   x))
                                         (chunk-spec-slot-spec request)))
                           (matches (if extra-spec
                                        (find-matching-chunks (define-chunk-spec-fct extra-spec) :chunks chunk-list)
                                      ;; reverse it to keep the ordering the same
                                      ;; relative to the older version and so that
                                      ;; things are consistent with different requests
                                      (nreverse chunk-list)))
                           (non-matches (when (or act sact)
                                          (set-difference chunk-list matches))))
                          (when (dm-act-level act 'high)
                            (dolist (c non-matches)
                              (model-output "Chunk ~s does not match" c)))
                          (when sact
                            (bt:with-lock-held ((dm-state-lock dm))
                              (setf (sact-trace-matches (dm-current-trace dm)) matches)
                              (setf (sact-trace-no-matches (dm-current-trace dm)) non-matches)))
                          matches)))))
        (setf (last-request-matches last-request) chunk-set)
        (if esc
            (dolist (x chunk-set)
              (compute-activation dm x request :params-provided t
                                  :act act :sact sact :mp mp :esc esc :offsets offsets
                                  :blc blc :bll bll :ol ol :act-scale act-scale
                                  :sa sa :spreading-hook spreading-hook :w-hook w-hook :sji-hook sji-hook
                                  :mas mas :nsji nsji :pm-hook pm-hook :ms ms :md md :sim-hook sim-hook
                                  :cache-sim-hook cache-sim-hook :noise-hook noise-hook :ans ans :bl-hook bl-hook)
              (setf (chunk-retrieval-activation x) (chunk-activation x))
              (setf (chunk-retrieval-time x) (mp-time-ms))
              (cond ((null best-val)
                     (setf best-val (chunk-activation x))
                     (push x best)
                     (when (dm-act-level act 'medium)
                       (model-output "Chunk ~s has the current best activation ~f" x best-val)))
                    ((= (chunk-activation x) best-val)
                     (push x best)
                     (when (dm-act-level act 'medium)
                       (model-output "Chunk ~s matches the current best activation ~f" x best-val)))
                    ((> (chunk-activation x) best-val)
                     (setf best-val (chunk-activation x))
                     (setf best (list x))
                     (when (dm-act-level act 'medium)
                       (model-output "Chunk ~s is now the current best with activation ~f" x best-val)))))
          (setf best (copy-list chunk-set)))
        (when (> (length best) 1)
          (if er
              (let ((b (random-item best)))
                (setf best (cons b (remove b best))))
            (setf best (sort best 'string<)))) ;; deterministic but unspecified...
        (setf (last-request-best last-request) best)
        (when (car set-hook)
          (let ((chunk-set-with-best (when best (cons (car best) (remove (car best) chunk-set)))))
            (dolist (x set-hook)
              (let ((val (dispatch-apply x chunk-set-with-best)))
                (when val
                  (if return-val
                      (progn
                        (print-warning "multiple set-hook functions returned a value - none used")
                        (setf return-val :error))
                    (setf return-val val)))))))
        (bt:with-lock-held ((dm-state-lock dm))
          (setf (dm-last-request dm) last-request)
          (cond ((and (listp return-val) (numberp (second return-val))
                      (chunk-p-fct (decode-string (first return-val))))
                 (let ((c (decode-string (first return-val))))
                   (setf (dm-busy dm) (schedule-event-relative (second return-val) 'retrieved-chunk
                                                               :module 'declarative
                                                               :destination 'declarative
                                                               :params (list c)
                                                               :details (concatenate 'string
                                                                          (symbol-name 'retrieved-chunk)
                                                                          " "
                                                                          (symbol-name (car return-val)))
                                                               :output 'medium))
                   (when sact
                     (setf (sact-trace-result-type (dm-current-trace dm)) :force)
                     (setf (sact-trace-result (dm-current-trace dm)) c))
                   (when (dm-act-level (dm-act dm) 'low)
                     (model-output "Retrieval-set-hook function forced retrieval of chunk ~s" c))))
                ((numberp return-val)
                 (setf (dm-busy dm) (schedule-event-relative return-val 'retrieval-failure
                                                             :module 'declarative
                                                             :destination 'declarative
                                                             :output 'low))
                 (when sact
                   (setf (sact-trace-result-type (dm-current-trace dm)) :force-fail))
                 (when (dm-act-level (dm-act dm) 'low)
                   (model-output "Retrieval-set-hook function forced retrieval failure")))
                ((or (null best)
                     (and esc
                          (< best-val rt)))
                 (setf (dm-busy dm) (schedule-event-relative (if esc
                                                                 (compute-activation-latency rt lf le)
                                                               0)
                                                             'retrieval-failure
                                                             :time-in-ms t
                                                             :module 'declarative
                                                             :destination 'declarative
                                                             :output 'low))
                 (when sact
                   (setf (sact-trace-result-type (dm-current-trace dm)) :fail)
                   (setf (sact-trace-result (dm-current-trace dm)) (when best rt)))
                 (when (dm-act-level act 'low)
                   (if best
                       (model-output "No chunk above the retrieval threshold: ~f" rt)
                     (model-output "No matching chunk found retrieval failure"))))
                ((= (length best) 1)
                 (setf (dm-busy dm) (schedule-event-relative (if esc
                                                                 (compute-activation-latency (chunk-activation (car best)) lf le)
                                                               0)
                                                             'retrieved-chunk
                                                             :time-in-ms t
                                                             :module 'declarative
                                                             :destination 'declarative
                                                             :params best
                                                             :details
                                                             (concatenate 'string
                                                               (symbol-name 'retrieved-chunk)
                                                               " "
                                                               (symbol-name (car best)))
                                                             :output 'medium))
                 (when sact
                   (setf (sact-trace-result-type (dm-current-trace dm)) :single)
                   (setf (sact-trace-result (dm-current-trace dm)) (cons (car best) (chunk-activation (car best)))))
                 (when (dm-act-level act 'low)
                   (model-output "Chunk ~s with activation ~f is the best" (car best) (chunk-activation (car best)))))
                (t
                 (let ((best1 (car best)))
                   (setf (dm-busy dm) (schedule-event-relative (if esc
                                                                   (compute-activation-latency (chunk-activation best1) lf le)
                                                                 0)
                                                               'retrieved-chunk
                                                               :time-in-ms t
                                                               :module 'declarative
                                                               :destination 'declarative
                                                               :params (list best1)
                                                               :details
                                                               (concatenate 'string
                                                                 (symbol-name 'retrieved-chunk)
                                                                 " "
                                                                 (symbol-name best1))
                                                               :output 'medium))
                   (when sact
                     (setf (sact-trace-result-type (dm-current-trace dm)) :multi)
                     (setf (sact-trace-result (dm-current-trace dm)) (cons best1 (chunk-activation best1))))
                   (when (dm-act-level act 'low)
                     (model-output "Chunk ~s chosen among the chunks with activation ~f" best1 (chunk-activation best1))))))
          (when sact
            (setf (dm-current-trace dm) nil))))))))
```