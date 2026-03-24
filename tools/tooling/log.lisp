(defpackage :minerva.tooling.log
  (:use :cl)
  (:export
   :log-info
   :log-test
   :log-lisp
   :log-native
   :log-fatal))

(in-package :minerva.tooling.log)

(defun %out (prefix stream format-string &rest args)
  (apply #'format stream (concatenate 'string prefix " " format-string "~%") args)
  (finish-output stream))

(defun log-info (format-string &rest args)
  (apply #'%out "[tool]" *standard-output* format-string args))

(defun log-test (format-string &rest args)
  (apply #'%out "[test]" *standard-output* format-string args))

(defun log-lisp (format-string &rest args)
  (apply #'%out "[lisp]" *standard-output* format-string args))

(defun log-native (format-string &rest args)
  (apply #'%out "[native]" *error-output* format-string args))

(defun log-fatal (format-string &rest args)
  (apply #'%out "[fatal]" *error-output* format-string args))
