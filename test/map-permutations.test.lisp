(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../map-permutations.lisp")
  (load "../while-collecting.lisp"))

(use-package :test-util)

(declaim (muffle-conditions warning))

(defun set-equal (x y)
  (null (set-exclusive-or x y :test #'equalp)))

(with-test (:name map-permutations)
  (assert (set-equal '(#(1 2 3) #(1 3 2) #(2 1 3) #(2 3 1) #(3 1 2) #(3 2 1))
                     (while-collecting (collect)
                       (do-permutations (perm (vector 1 2 3) 3)
                         (collect (copy-seq perm))))))
  (assert (set-equal '(#(1 2 3) #(1 3 2) #(2 1 3) #(2 3 1) #(3 1 2) #(3 2 1))
                     (while-collecting (collect)
                       (do-permutations (perm (vector 1 2 3))
                         (collect (copy-seq perm))))))
  (assert (set-equal '(#(1 2) #(1 3) #(2 1) #(2 3) #(3 1) #(3 2))
                     (while-collecting (collect)
                       (do-permutations (perm (vector 1 2 3) 2)
                         (collect (copy-seq perm))))))
  (assert (set-equal '(#(1) #(2) #(3))
                     (while-collecting (collect)
                       (do-permutations (perm (vector 1 2 3) 1)
                         (collect (copy-seq perm))))))
  (assert (set-equal '(#())
                     (while-collecting (collect)
                       (do-permutations (perm (vector 1 2 3) 0)
                         (collect (copy-seq perm))))))

  ;; empty case
  (assert (set-equal '(#())
                     (while-collecting (collect)
                       (do-permutations (perm (vector))
                         (collect (copy-seq perm)))))))
