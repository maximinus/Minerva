(load (merge-pathnames #P"tooling/runner.lisp"
                       (make-pathname :name nil :type nil :defaults *load-truename*)))

(in-package :cl-user)

(minerva.tooling.runner:run-tool-mode
 :test
 (lambda ()
   (minerva.tooling.runner:load-minerva-asd)
   (minerva.tooling.runner:with-phase (:test)
     (asdf:test-system "minerva/tests")))
 :default-exit 1)
