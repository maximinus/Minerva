(in-package :minerva.gui)

(defun run-gui-layout-tests ()
  (setf *test-count* 0
        *test-failures* 0)
  (dolist (test-symbol (%collect-test-symbols))
    (%run-test-case test-symbol))
  (format t "~%Executed ~D assertions.~%" *test-count*)
  (if (zerop *test-failures*)
      (format t "All GUI layout tests passed.~%")
      (error "GUI layout tests failed: ~D assertion(s)." *test-failures*)))
