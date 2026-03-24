(asdf:defsystem "minerva"
  :description "Minerva Lisp IDE core systems"
  :version "0.1.0"
  :serial t
  :components
  ((:file "src/minerva/conditions")
   (:file "src/minerva/gfx/ffi")
   (:file "src/minerva/gfx/backend")
   (:file "src/minerva/gui/core")))

(asdf:defsystem "minerva/tests"
  :description "Minerva GUI and graphics tests"
  :depends-on ("minerva")
  :serial t
  :components
  ((:file "tests/minerva/gui/tests")
   (:file "tests/minerva/gfx/tests"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (let ((run-gui-fn (find-symbol "RUN-GUI-LAYOUT-TESTS" :minerva.gui))
                   (run-gfx-fn (find-symbol "RUN-GFX-RESOURCE-TESTS" :minerva.gfx.tests)))
               (unless (and run-gui-fn (fboundp run-gui-fn))
                 (error "RUN-GUI-LAYOUT-TESTS not found in MINERVA.GUI"))
               (unless (and run-gfx-fn (fboundp run-gfx-fn))
                 (error "RUN-GFX-RESOURCE-TESTS not found in MINERVA.GFX.TESTS"))
               (funcall run-gui-fn)
               (funcall run-gfx-fn))))
