(clear-all)
            

(define-model example-of-dm-hooks
    
  (sgp :retrieved-chunk-hook chunk-retrieved
       :retrieval-set-hook override-retrieval
       :chunk-add-hook chunk-added
       :chunk-merge-hook chunk-merged)
  
  (sgp :esc t :bll .5 :ol nil :ans .2 :rt -10 :seed (100 0))
  
  (chunk-type test value)
  (chunk-type goal step)
  
  (add-dm
   (v1 value 1))
  
  (p start
     ?goal>
     buffer empty
     ==>
     +goal>
     
     +imaginal>
       value 2)
  
  (p normal-add-to-dm
     =goal>
       step nil
     =imaginal>
     ==>
     =goal>
       step 1
     +imaginal>
       value 2)
  
  (p normal-merge
     =goal>
       step 1
     =imaginal>
     ==>
     =goal>
       step 2
     +retrieval>
       value 1)
  
  (p add-new-chunk-show-copied-history
     =goal>
       step 2
     =retrieval>
     ==>
     =goal> 
       step 3
     =retrieval>
       value 3
     +retrieval>
       value 1)
  
  (p merge-and-eliminate-reference
     =goal>
       step 3
     =retrieval>
     ==>
     =goal>
       step 4
     +example>
       position second
     +retrieval>
     )
  )

#| Model run stoping to show the declarative parameters for the chunks
   when things happen normally and when they are modified, as well as a
   retrieval that was overridden to retrieve the second highest activation.

? (reset)
T

;;; Declarative parameters for the original chunk in memory 

? (sdp)
Declarative parameters for chunk V1:
 :Activation  1.463
 :Permanent-Noise  0.000
 :Base-Level  1.498
 :Creation-Time 0.000
 :Reference-List (0.000)
(V1)
? (run .3)
     0.000   PROCEDURAL             CONFLICT-RESOLUTION
     0.050   PROCEDURAL             PRODUCTION-FIRED START
     0.050   PROCEDURAL             CLEAR-BUFFER GOAL
     0.050   PROCEDURAL             CLEAR-BUFFER IMAGINAL
     0.050   GOAL                   SET-BUFFER-CHUNK GOAL (ISA CHUNK)
     0.050   PROCEDURAL             CONFLICT-RESOLUTION
     0.250   IMAGINAL               SET-BUFFER-CHUNK IMAGINAL (VALUE 2)
     0.250   PROCEDURAL             CONFLICT-RESOLUTION
     0.300   PROCEDURAL             PRODUCTION-FIRED NORMAL-ADD-TO-DM
     0.300   PROCEDURAL             CLEAR-BUFFER IMAGINAL
     0.300   PROCEDURAL             CONFLICT-RESOLUTION
     0.300   ------                 Stopped because time limit reached
0.3
27
NIL


;;; A new chunk was added (imaginal-chunk0-0)  and gets the normal parameter update.
;;; The original chunk is unchanged.


? (sdp)
Declarative parameters for chunk IMAGINAL-CHUNK0-0:
 :Activation  1.355
 :Permanent-Noise  0.000
 :Base-Level  1.498
 :Creation-Time 0.300
 :Reference-List (0.300)
Declarative parameters for chunk V1:
 :Activation  0.792
 :Permanent-Noise  0.000
 :Base-Level  0.602
 :Creation-Time 0.000
 :Reference-List (0.000)
(IMAGINAL-CHUNK0-0 V1)
? (run-until-time .55)
     0.500   IMAGINAL               SET-BUFFER-CHUNK IMAGINAL (VALUE 2)
     0.500   PROCEDURAL             CONFLICT-RESOLUTION
     0.550   PROCEDURAL             PRODUCTION-FIRED NORMAL-MERGE
     0.550   PROCEDURAL             CLEAR-BUFFER IMAGINAL
     0.550   PROCEDURAL             CLEAR-BUFFER RETRIEVAL
     0.550   DECLARATIVE            start-retrieval
     0.550   PROCEDURAL             CONFLICT-RESOLUTION
     0.550   ------                 Stopped because time limit reached
0.25
16
NIL


;;; Merged a chunk with chunk imaginal-chunk0-0 and it got a new reference as usual.


? (sdp)
Declarative parameters for chunk IMAGINAL-CHUNK0-0:
 :Activation  1.928
 :Permanent-Noise  0.000
 :Base-Level  1.868
 :Creation-Time 0.300
 :Reference-List (0.550 0.300)
Declarative parameters for chunk V1:
 :Activation  0.370
 :Permanent-Noise  0.000
 :Base-Level  0.299
 :Creation-Time 0.000
 :Reference-List (0.000)
 :Last-Retrieval-Activation  0.370
 :Last-Retrieval-Time  0.550
(IMAGINAL-CHUNK0-0 V1)
? (run-until-time 1.4)
     1.241   DECLARATIVE            RETRIEVED-CHUNK V1
     1.241   DECLARATIVE            SET-BUFFER-CHUNK RETRIEVAL V1
     1.241   PROCEDURAL             CONFLICT-RESOLUTION
     1.291   PROCEDURAL             PRODUCTION-FIRED ADD-NEW-CHUNK-SHOW-COPIED-HISTORY
     1.291   PROCEDURAL             CLEAR-BUFFER RETRIEVAL
Chunk RETRIEVAL-CHUNK0-0 being added to DM and getting starting history from chunk V1.
     1.291   DECLARATIVE            start-retrieval
     1.291   PROCEDURAL             CONFLICT-RESOLUTION
     1.400   ------                 Stopped because time limit reached
0.85
15
NIL


;;; This time retrieval-chunk0-0 was added to memory, but its parameters were
;;; adjusted to match the chunk that had been retrieved, v1, and then it got the
;;; new reference.


? (sdp)
Declarative parameters for chunk RETRIEVAL-CHUNK0-0:
 :Activation  1.015
 :Permanent-Noise  0.000
 :Base-Level  1.354
 :Creation-Time 0.000
 :Reference-List (1.291 0.000)
Declarative parameters for chunk IMAGINAL-CHUNK0-0:
 :Activation  1.061
 :Permanent-Noise  0.000
 :Base-Level  0.712
 :Creation-Time 0.300
 :Reference-List (0.550 0.300)
Declarative parameters for chunk V1:
 :Activation  0.902
 :Permanent-Noise  0.000
 :Base-Level -0.168
 :Creation-Time 0.000
 :Reference-List (0.000)
 :Last-Retrieval-Activation -0.149
 :Last-Retrieval-Time  1.291
(RETRIEVAL-CHUNK0-0 IMAGINAL-CHUNK0-0 V1)
? (sgp :act t)
(T)
? (run 10)
     2.717   DECLARATIVE            RETRIEVED-CHUNK V1
     2.717   DECLARATIVE            SET-BUFFER-CHUNK RETRIEVAL V1
     2.717   PROCEDURAL             CONFLICT-RESOLUTION
     2.767   PROCEDURAL             PRODUCTION-FIRED MERGE-AND-ELIMINATE-REFERENCE
     2.767   PROCEDURAL             CLEAR-BUFFER EXAMPLE
     2.767   PROCEDURAL             CLEAR-BUFFER RETRIEVAL
Chunk RETRIEVAL-CHUNK0 being merged into DM but eliminating the reference being added to chunk V1.
     2.767   DECLARATIVE            start-retrieval
Chunk RETRIEVAL-CHUNK0-0 matches
Chunk IMAGINAL-CHUNK0-0 matches
Chunk V1 matches
Computing activation for chunk RETRIEVAL-CHUNK0-0
Computing base-level
Starting with blc: 0.0
Computing base-level from 2 references (1.368 0.000)
  creation time: 0.000 decay: 0.5  Optimized-learning: NIL
base-level value: 0.36923242
Total base-level: 0.36923242
Adding transient noise 0.19051288
Adding permanent noise 0.0
Chunk RETRIEVAL-CHUNK0-0 has an activation of: 0.5597453
Chunk RETRIEVAL-CHUNK0-0 has the current best activation 0.5597453
Computing activation for chunk IMAGINAL-CHUNK0-0
Computing base-level
Starting with blc: 0.0
Computing base-level from 2 references (0.550 0.300)
  creation time: 0.300 decay: 0.5  Optimized-learning: NIL
base-level value: 0.26871443
Total base-level: 0.26871443
Adding transient noise 0.071102396
Adding permanent noise 0.0
Chunk IMAGINAL-CHUNK0-0 has an activation of: 0.3398168
Computing activation for chunk V1
Computing base-level
Starting with blc: 0.0
Computing base-level from 1 references (0.000)
  creation time: 0.000 decay: 0.5  Optimized-learning: NIL
base-level value: -0.5088818
Total base-level: -0.5088818
Adding transient noise 0.060851034
Adding permanent noise 0.0
Chunk V1 has an activation of: -0.44803077
Chunk RETRIEVAL-CHUNK0-0 had the highest activation but retrieving the SECOND highest chunk instead.
Retrieval-set-hook function forced retrieval of chunk IMAGINAL-CHUNK0-0
     2.767   PROCEDURAL             CONFLICT-RESOLUTION
     3.479   DECLARATIVE            RETRIEVED-CHUNK IMAGINAL-CHUNK0-0
     3.479   DECLARATIVE            SET-BUFFER-CHUNK RETRIEVAL IMAGINAL-CHUNK0-0
     3.479   PROCEDURAL             CONFLICT-RESOLUTION
     3.479   ------                 Stopped because no events left to process
2.079
19
NIL
?

;;; Shown in the trace, a retrieval request was made with retrieval-chunk0-0 having the
;;; highest activation, but because of the '+example> position second' request in the
;;; merge-and-eliminate-reference production the chunk with the second highest activation,
;;; imaginal-chunk0-0 was retrieved instead.


;;; Also, a chunk was merged that matched the previously retrieved chunk, v1, and
;;; it removed the new reference that had been added to v1 (it still only has one reference).


(sgp :act nil)
(NIL)
? (sdp)
Declarative parameters for chunk RETRIEVAL-CHUNK0-0:
 :Activation  0.156
 :Permanent-Noise  0.000
 :Base-Level  0.298
 :Creation-Time 0.000
 :Reference-List (1.291 0.000)
 :Last-Retrieval-Activation  0.769
 :Last-Retrieval-Time  2.501
Declarative parameters for chunk IMAGINAL-CHUNK0-0:
 :Activation  0.489
 :Permanent-Noise  0.000
 :Base-Level  0.224
 :Creation-Time 0.300
 :Reference-List (0.550 0.300)
 :Last-Retrieval-Activation  0.725
 :Last-Retrieval-Time  2.501
Declarative parameters for chunk V1:
 :Activation -0.858
 :Permanent-Noise  0.000
 :Base-Level -0.547
 :Creation-Time 0.000
 :Reference-List (0.000)
 :Last-Retrieval-Activation -0.164
 :Last-Retrieval-Time  2.501
(RETRIEVAL-CHUNK0-0 IMAGINAL-CHUNK0-0 V1)
?

|#