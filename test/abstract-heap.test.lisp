(eval-when (:compile-toplevel :load-toplevel :execute)
  (load "test-util")
  (load "../abstract-heap.lisp"))

(use-package :test-util)

(define-binary-heap test-heap
  :order #'<
  :element-type (unsigned-byte 32))

(with-test (:name abstract-heap)
  (let ((h (make-test-heap 7)))
    (assert (= 0 (test-heap-count h)))
    (dolist (x '(6 18 22 15 27 9 11))
      (test-heap-push x h))
    (assert (= 6 (test-heap-peek h)))
    (assert (= 7 (test-heap-count h)))
    (test-heap-push 0 h)
    (assert (= 8 (test-heap-count h)))
    (assert (= 0 (test-heap-peek h)))
    (assert (equal '(0 6 9 11 15 18 22 27)
                   (loop repeat 8 collect (test-heap-pop h))))
    (assert (test-heap-empty-p h))
    (signals heap-empty-error (test-heap-pop h)))
  (assert (typep (test-heap-data (make-test-heap 10))
                 '(simple-array (unsigned-byte 32) (*)))))
