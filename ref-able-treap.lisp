(setf *print-circle* t)

;; Treap accessible by index (O(log(n))).
;; Virtually it works like std::set of C++ or TreeSet of Java.

(defstruct (treap (:constructor %make-treap (key priority &key left right (count 1)))
                  (:copier nil)
                  (:conc-name %treap-))
  key
  (priority 0 :type (integer 0 #.most-positive-fixnum))
  (count 0 :type (integer 0 #.most-positive-fixnum))
  (left nil :type (or null treap))
  (right nil :type (or null treap)))

(declaim (inline treap-count))
(defun treap-count (treap)
  "Returns the size of the (nullable) TREAP."
  (declare ((or null treap) treap))
  (if (null treap)
      0
      (%treap-count treap)))

(declaim (inline update-count))
(defun update-count (treap)
  (declare (treap treap))
  (setf (%treap-count treap)
        (+ 1
           (treap-count (%treap-left treap))
           (treap-count (%treap-right treap)))))

(defun treap-find (key treap &key (test #'<))
  "Finds the sub-treap of TREAP whose key satisfies (and (not (treap-order
key (%treap-key sub-treap))) (not (treap-order (%treap-key sub-treap) key)))
and returns KEY. Returns NIL if KEY is not contained."
  (declare (function test)
           ((or null treap) treap))
  (cond ((null treap) nil)
        ((funcall test key (%treap-key treap))
         (treap-find key (%treap-left treap) :test test))
        ((funcall test (%treap-key treap) key)
         (treap-find key (%treap-right treap) :test test))
        (t key)))

(defun treap-bisect-left (value treap &key (test #'<))
  "Returns the smallest index and the corresponding key that satisfies
TREAP[index] >= VALUE. Returns the size of TREAP and VALUE if TREAP[size-1] <
VALUE."
  (declare (function test))
  (labels ((recurse (count treap)
             (declare ((integer 0 #.most-positive-fixnum) count))
             (cond ((null treap) (values nil nil))
                   ((funcall test (%treap-key treap) value)
                    (recurse count (%treap-right treap)))
                   (t (let ((left-count (- count (treap-count (%treap-right treap)) 1)))
                        (multiple-value-bind (idx key)
                            (recurse left-count (%treap-left treap))
                          (if idx
                              (values idx key)
                              (values left-count (%treap-key treap)))))))))
    (declare (ftype (function * (values t t &optional)) recurse))
    (multiple-value-bind (idx key)
        (recurse (treap-count treap) treap)
      (if idx
          (values idx key)
          (values (treap-count treap) value)))))

(declaim (ftype (function * (values (or null treap) (or null treap) &optional)) treap-split))
(defun treap-split (key treap &key (test #'<))
  "Destructively splits the TREAP with reference to KEY and returns two treaps,
the smaller sub-treap (< KEY) and the larger one (>= KEY)."
  (declare (function test)
           ((or null treap) treap))
  (cond ((null treap)
         (values nil nil))
        ((funcall test (%treap-key treap) key)
         (multiple-value-bind (left right)
             (treap-split key (%treap-right treap) :test test)
           (setf (%treap-right treap) left)
           (update-count treap)
           (values treap right)))
        (t
         (multiple-value-bind (left right)
             (treap-split key (%treap-left treap) :test test)
           (setf (%treap-left treap) right)
           (update-count treap)
           (values left treap)))))

(declaim (inline treap-insert))
(defun treap-insert (key treap &key (test #'<))
  "Destructively inserts KEY into TREAP and returns the resultant treap. You
cannot rely on the side effect. Use the returned value.

The behavior is undefined when duplicated keys are inserted."
  (declare ((or null treap) treap)
           (function test))
  (labels ((recurse (node treap)
             (declare (treap node))
             (cond ((null treap) node)
                   ((> (%treap-priority node) (%treap-priority treap))
                    (setf (values (%treap-left node) (%treap-right node))
                          (treap-split (%treap-key node) treap :test test))
                    (update-count node)
                    node)
                   (t
                    (if (funcall test (%treap-key node) (%treap-key treap))
                        (setf (%treap-left treap)
                              (recurse node (%treap-left treap)))
                        (setf (%treap-right treap)
                              (recurse node (%treap-right treap))))
                    (update-count treap)
                    treap))))
    (recurse (%make-treap key (random most-positive-fixnum)) treap)))

(defun treap (test &rest keys)
  (loop with res = nil
        for key in keys
        do (setf res (treap-insert key res :test test))
        finally (return res)))

;; Reference: https://cp-algorithms.com/data_structures/treap.html
;; TODO: take a sorted list as the argument
(declaim (inline make-treap))
(defun make-treap (sorted-vector)
  "Makes a treap from the given SORTED-VECTOR in O(n). Note that this function
doesn't check if the SORTED-VECTOR is properly sorted w.r.t. your intended
order."
  (declare (vector sorted-vector))
  (labels ((heapify (top)
             (when top
               (let ((prioritized-node top))
                 (when (and (%treap-left top)
                            (> (%treap-priority (%treap-left top))
                               (%treap-priority prioritized-node)))
                   (setq prioritized-node (%treap-left top)))
                 (when (and (%treap-right top)
                            (> (%treap-priority (%treap-right top))
                               (%treap-priority prioritized-node)))
                   (setq prioritized-node (%treap-right top)))
                 (unless (eql prioritized-node top)
                   (rotatef (%treap-priority prioritized-node)
                            (%treap-priority top))
                   (heapify prioritized-node)))))
           (build (l r)
             (declare ((integer 0 #.most-positive-fixnum) l r))
             (if (= l r)
                 nil
                 (let* ((mid (ash (+ l r) -1))
                        (node (%make-treap (aref sorted-vector mid)
                                           (random most-positive-fixnum))))
                   (setf (%treap-left node) (build l mid))
                   (setf (%treap-right node) (build (+ mid 1) r))
                   (heapify node)
                   (update-count node)
                   node))))
    (build 0 (length sorted-vector))))

(defun treap-merge (left right)
  "Destructively merges two treaps. Assumes that all keys of LEFT are smaller
(or larger, depending on the order) than those of RIGHT."
  (declare ((or null treap) left right))
  (cond ((null left) right)
        ((null right) left)
        ((> (%treap-priority left) (%treap-priority right))
         (setf (%treap-right left)
               (treap-merge (%treap-right left) right))
         (update-count left)
         left)
        (t
         (setf (%treap-left right)
               (treap-merge left (%treap-left right)))
         (update-count right)
         right)))

(defun treap-delete (key treap &key (test #'<))
  "Destructively deletes the KEY in TREAP and returns the resultant treap. You
cannot rely on the side effect. Use the returned value."
  (declare ((or null treap) treap)
           (function test))
  (cond ((null treap) nil)
        ((funcall test key (%treap-key treap))
         (setf (%treap-left treap) (treap-delete key (%treap-left treap) :test test))
         (update-count treap)
         treap)
        ((funcall test (%treap-key treap) key)
         (setf (%treap-right treap) (treap-delete key (%treap-right treap) :test test))
         (update-count treap)
         treap)
        (t
         (treap-merge (%treap-left treap) (%treap-right treap)))))

(defun treap-map (function treap)
  "Successively applies FUNCTION to TREAP[0], ..., TREAP[SIZE-1]. FUNCTION must
take one argument."
  (declare (function function))
  (when treap
    (treap-map function (%treap-left treap))
    (funcall function (%treap-key treap))
    (treap-map function (%treap-right treap))))

(defmethod print-object ((object treap) stream)
  (print-unreadable-object (object stream :type t)
    (let ((init t))
      (treap-map (lambda (key)
                   (if init
                       (setf init nil)
                       (write-char #\  stream))
                   (write key :stream stream))
                 object))))

(define-condition invalid-treap-index-error (type-error)
  ((treap :initarg :treap :reader invalid-treap-index-error-treap)
   (index :initarg :index :reader invalid-treap-index-error-index))
  (:report
   (lambda (condition stream)
     (format stream "Invalid index ~W for treap ~S."
             (invalid-treap-index-error-index condition)
             (invalid-treap-index-error-treap condition)))))

(declaim (inline treap-ref))
(defun treap-ref (treap index)
  "Index access"
  (declare ((or null treap) treap)
           ((integer 0 #.most-positive-fixnum) index))
  (when (>= index (treap-count treap))
    (error 'invalid-treap-index-error :treap treap :index index))
  (labels ((%ref (treap index)
             (declare ((integer 0 #.most-positive-fixnum) index))
             (let ((left-count (treap-count (%treap-left treap))))
               (cond ((< index left-count)
                      (%ref (%treap-left treap) index))
                     ((> index left-count)
                      (%ref (%treap-right treap) (- index left-count 1)))
                     (t (%treap-key treap))))))
    (%ref treap index)))

;;;
;;; For development
;;;

(defun copy-treap (treap)
  "For development. Recursively copies the whole TREAP."
  (declare ((or null treap) treap))
  (if (null treap)
      nil
      (%make-treap (%treap-key treap)
                   (%treap-priority treap)
                   :left (copy-treap (%treap-left treap))
                   :right (copy-treap (%treap-right treap))
                   :count (%treap-count treap))))
