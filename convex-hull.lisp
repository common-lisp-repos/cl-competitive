;;;
;;; 2D convex hull of points (Monotone Chain Algorithm)
;;; Complexity: O(nlog(n))
;;;

(declaim (inline make-convex-hull!))
(defun make-convex-hull! (points &optional (eps 0))
  "Returns the vector of the vertices of the convex hull, which are in the
anticlockwise direction. This function sorts POINTS as a side effect.

If EPS is non-negative, three vertices in a straight line are excluded (when the
calculation error is within EPS, of course); they are allowed if EPS is
negative.

POINTS := vector of complex number"
  (declare (inline sort)
           (vector points))
  (macrolet ((outer (p1 p2)
               `(let ((c1 ,p1)
                      (c2 ,p2))
                  (- (* (realpart c1) (imagpart c2))
                     (* (imagpart c1) (realpart c2))))))
    (when (<= (length points) 1)
      (return-from make-convex-hull! (copy-seq points)))
    (let* ((n (length points))
           (end 0)
           (res (make-array (* n 2) :element-type (array-element-type points)))
           (points (sort points (lambda (p1 p2)
                                  (if (= (realpart p1) (realpart p2))
                                      (< (imagpart p1) (imagpart p2))
                                      (< (realpart p1) (realpart p2)))))))
      (declare (fixnum end))
      (do ((i 0 (+ i 1)))
          ((= i n))
        (loop (if (and (> end 1)
                       (<= (outer (- (aref res (- end 1)) (aref res (- end 2)))
                                  (- (aref points i) (aref res (- end 1))))
                           eps))
                  (decf end)
                  (return)))
        (setf (aref res end) (aref points i))
        (incf end))
      (let ((tmp-end end))
        (do ((i (- n 2) (- i 1)))
            ((< i 0))
          (loop (if (and (> end tmp-end)
                         (<= (outer (- (aref res (- end 1)) (aref res (- end 2)))
                                    (- (aref points i) (aref res (- end 1))))
                             eps))
                    (decf end)
                    (return)))
          (setf (aref res end) (aref points i))
          (incf end)))
      (adjust-array res (- end 1)))))
