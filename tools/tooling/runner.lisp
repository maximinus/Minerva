(require :asdf)

(load (merge-pathnames #P"log.lisp"
                       (make-pathname :name nil :type nil :defaults *load-truename*)))

(defpackage :minerva.tooling.runner
  (:use :cl)
  (:import-from :minerva.tooling.log
                :log-info
                :log-lisp
                :log-fatal)
  (:export
   :with-phase
   :load-minerva-asd
   :project-root
   :run-tool-mode))

(in-package :minerva.tooling.runner)

(defparameter *runner-source-file* (or *load-truename* *load-pathname*))

(defparameter *tool-mode* :unknown)
(defparameter *tool-phase* :startup)

(defmacro with-phase ((phase) &body body)
  `(let ((*tool-phase* ,phase))
     ,@body))

(defun project-root ()
  (let* ((tooling-dir (make-pathname :name nil :type nil :defaults *runner-source-file*))
         (tools-dir (merge-pathnames "../" tooling-dir))
         (root-dir (merge-pathnames "../" tools-dir)))
    (truename root-dir)))

(defun %quit (code)
  #+sbcl (sb-ext:exit :code code)
  #-sbcl (error "Unsupported Lisp implementation for tooling exit."))

(defun %condition-type-name (condition)
  (string-upcase (symbol-name (class-name (class-of condition)))))

(defun %condition-name-contains-p (condition fragment)
  (search (string-upcase fragment)
          (%condition-type-name condition)
          :test #'char=))

(defun %native-last-error ()
  (let* ((pkg (find-package :minerva.gfx))
         (sym (and pkg (find-symbol "BACKEND-LAST-ERROR" pkg))))
    (when (and sym (fboundp sym))
      (let ((value (ignore-errors (funcall (symbol-function sym)))))
        (when (and value (stringp value) (> (length value) 0))
          value)))))

(defun %current-test-name ()
  (let* ((pkg (find-package :minerva.gui))
         (fn-sym (and pkg (find-symbol "CURRENT-TEST-NAME" pkg)))
         (var-sym (and pkg (find-symbol "*CURRENT-TEST-NAME*" pkg))))
    (cond
      ((and fn-sym (fboundp fn-sym))
       (ignore-errors (funcall (symbol-function fn-sym))))
      ((and var-sym (boundp var-sym))
       (symbol-value var-sym))
      (t nil))))

(defun %classify-condition (condition default-exit)
  (cond
    ((%condition-name-contains-p condition "MINERVA-TEST-ERROR") 1)
    ((%condition-name-contains-p condition "MINERVA-ERROR") (or default-exit 1))
    ((or (%condition-name-contains-p condition "COMPILE-FILE-ERROR")
         (%condition-name-contains-p condition "INPUT-ERROR-IN-LOAD")
         (%condition-name-contains-p condition "LOAD-SYSTEM-DEFINITION-ERROR")
         (%condition-name-contains-p condition "SIMPLE-FILE-ERROR")
         (%condition-name-contains-p condition "FILE-ERROR"))
     2)
    (t 3)))

(defun %print-crash-context (condition exit-code)
  (log-fatal "mode=~A phase=~A" *tool-mode* *tool-phase*)
  (log-fatal "condition=~A" (%condition-type-name condition))
  (log-fatal "message=~A" condition)
  (let ((native-error (%native-last-error))
        (test-name (%current-test-name)))
    (when native-error
      (log-fatal "native-last-error=~A" native-error))
    (when test-name
      (log-fatal "current-test=~A" test-name)))
  (log-fatal "exit-code=~A" exit-code))

(defun load-minerva-asd ()
  (with-phase (:load)
    (require :asdf)
    (setf *compile-verbose* nil
          *compile-print* nil
          *load-verbose* nil
          asdf:*asdf-verbose* nil)
    (let ((asd-path (merge-pathnames #P"minerva.asd" (project-root))))
      (log-lisp "load-asd path=~A" asd-path)
      (asdf:load-asd asd-path))))

(defun run-tool-mode (mode thunk &key default-exit)
  (let ((*tool-mode* mode))
    (handler-case
        (progn
          (funcall thunk)
          (log-info "mode=~A status=ok" mode)
          (%quit 0))
      (serious-condition (condition)
        (let ((exit-code (%classify-condition condition default-exit)))
          (%print-crash-context condition exit-code)
          (%quit exit-code))))))
