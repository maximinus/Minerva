(load (merge-pathnames #P"tooling/runner.lisp"
                       (make-pathname :name nil :type nil :defaults *load-truename*)))

(in-package :cl-user)

(minerva.tooling.runner:run-tool-mode
 :load-check
 (lambda ()
   (minerva.tooling.runner:load-minerva-asd)
   (minerva.tooling.runner:with-phase (:load)
     (asdf:load-system "minerva/tests")))
 :default-exit 2)
