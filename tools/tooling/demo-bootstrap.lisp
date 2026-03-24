(require :asdf)

(defpackage :minerva.tooling.demo-bootstrap
  (:use :cl)
  (:export :load-minerva))

(in-package :minerva.tooling.demo-bootstrap)

(defparameter *demo-bootstrap-source-file* (or *load-truename* *load-pathname*))

(defun project-root ()
  (let* ((tooling-dir (make-pathname :name nil :type nil :defaults *demo-bootstrap-source-file*))
         (tools-dir (merge-pathnames "../" tooling-dir))
         (root-dir (merge-pathnames "../" tools-dir)))
    (truename root-dir)))

(defun load-minerva ()
  (let ((asd-path (merge-pathnames #P"minerva.asd" (project-root))))
    (asdf:load-asd asd-path)
    (asdf:load-system "minerva")))
