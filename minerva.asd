(asdf:defsystem "minerva"
  :description "Minerva Lisp IDE core systems"
  :version "0.1.0"
  :serial t
  :components
  ((:file "src/minerva/gfx/ffi")
   (:file "src/minerva/gfx/backend")
   (:file "src/minerva/gui/core")))

(asdf:defsystem "minerva/tests"
  :description "Minerva GUI layout tests"
  :depends-on ("minerva")
  :serial t
  :components
  ((:file "tests/minerva/gui/tests"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (let ((run-fn (find-symbol "RUN-GUI-LAYOUT-TESTS" :minerva.gui)))
               (unless (and run-fn (fboundp run-fn))
                 (error "RUN-GUI-LAYOUT-TESTS not found in MINERVA.GUI"))
               (funcall run-fn))))
