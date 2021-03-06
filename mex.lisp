(defun mex (&rest args)
  "Returns the minimum non-negative integer not contained in ARGS."
  (let ((table (make-hash-table :test #'eql)))
    (dolist (x args)
      (setf (gethash x table) t))
    (loop for x of-type fixnum from 0
          unless (gethash x table)
          do (return x))))
