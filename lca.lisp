;;;
;;; Lowest common anscestor of tree by bisection
;;; construct: O(nlog(n))
;;; query: O(log(n))
;;;

;; PAY ATTENTION TO THE STACK SIZE( as CONSTRUCT-LCA-TABLE does DFS)!

(deftype lca-vertex-number () '(signed-byte 32))

(defstruct (lca-table
            (:constructor make-lca-table
                (size &aux (depths (make-array size :element-type 'lca-vertex-number))
                      ;; requires 1 + log_2{size-1}
                           (parents (make-array (list size (+ 1 (integer-length (- size 2)))) :element-type 'lca-vertex-number))))
            (:conc-name lca-))
  (depths nil :type (simple-array lca-vertex-number (*)))
  (parents nil :type (simple-array lca-vertex-number (* *))))

(defun construct-lca-table (root graph)
  (declare ((simple-array list (*)) graph))
  (let* ((size (length graph))
         (lca-table (make-lca-table size))
         (depths (lca-depths lca-table))
         (parents (lca-parents lca-table))
         (max-log-v (array-dimension parents 1)))
    (labels ((dfs (v prev-v depth)
               (declare (lca-vertex-number v prev-v))
               (setf (aref depths v) depth)
               (setf (aref parents v 0) prev-v)
               (dolist (neighbor (aref graph v))
                 (declare (lca-vertex-number neighbor))
                 (unless (= neighbor prev-v)
                   (dfs neighbor v (+ 1 depth))))))
      (dfs root -1 0)
      (dotimes (k (- max-log-v 1))
        (dotimes (v size)
          (if (= -1 (aref parents v k))
              (setf (aref parents v (+ k 1)) -1)
              (setf (aref parents v (+ k 1)) (aref parents (aref parents v k) k)))))
      lca-table)))

(defun get-lca (u v lca-table)
  (declare (lca-vertex-number u v))
  (let* ((depths (lca-depths lca-table))
         (parents (lca-parents lca-table))
         (max-log-v (array-dimension parents 1)))
    ;; Ensures depth[u] <= depth[v]
    (when (> (aref depths u) (aref depths v)) (rotatef u v))
    (dotimes (k max-log-v)
      (when (logbitp k (- (aref depths v) (aref depths u)))
        (setf v (aref parents v k))))
    (if (= u v)
        u
        (loop for k from (- max-log-v 1) downto 0
              unless (= (aref parents u k) (aref parents v k))
              do (setf u (aref parents u k)
                       v (aref parents v k))
              finally (return (aref parents u 0))))))

(defun distance-on-tree (u v lca-table)
  (let ((depths (lca-depths lca-table))
        (lca (get-lca u v lca-table)))
    (+ (- (aref depths u) (aref depths lca))
       (- (aref depths v) (aref depths lca)))))

(defun test-lca ()
  (let* ((graph (make-array 8 :element-type 'list :initial-contents '((1 2) (0 3 4) (0 5) (1) (1 6 7) (2) (4) (4))))
         (graph2 (make-array 9 :element-type 'list :initial-contents '((1) (0 2) (1 3) (2 4) (3 5) (4 6) (5 7) (6 8) (7))))
         (table (construct-lca-table 0 graph))
         (table2 (construct-lca-table 0 graph2)))
    (assert (= 4 (get-lca 6 7 table)))
    (assert (= 1 (get-lca 3 7 table)))
    (assert (= 0 (get-lca 3 5 table)))
    (assert (= 0 (get-lca 5 3 table)))
    (assert (= 4 (get-lca 4 4 table)))
    (assert (= 5 (distance-on-tree 7 5 table)))
    (assert (= 0 (distance-on-tree 4 4 table)))
    (assert (= 1 (distance-on-tree 3 1 table)))
    (dotimes (u 9)
      (dotimes (v 9)
        (assert (= (min u v) (get-lca u v table2)))))))
