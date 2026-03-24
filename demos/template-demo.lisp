;; Run from project root with: sbcl --script demos/template-demo.lisp

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-template-demo (&key (title "Minerva Template Demo") (width 800) (height 600) (max-runtime-ms 3000))
  (declare (ignorable title width height max-runtime-ms))
  (format t "Template demo loaded. Replace RUN-TEMPLATE-DEMO body with your demo logic.~%"))

(run-template-demo)
