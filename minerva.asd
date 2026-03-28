(asdf:defsystem "minerva"
  :description "Minerva Lisp IDE core systems"
  :version "0.1.0"
  :serial t
  :components
  ((:file "src/minerva/conditions")
   (:file "src/minerva/common")
   (:file "src/minerva/gfx/ffi")
   (:file "src/minerva/gfx/backend")
    (:file "src/minerva/gui/core")
    (:file "src/minerva/gui/window")
    (:file "src/minerva/gui/hbox")
    (:file "src/minerva/gui/vbox")
    (:file "src/minerva/gui/color-rect")
    (:file "src/minerva/gui/filler")
    (:file "src/minerva/gui/image")
    (:file "src/minerva/gui/label")
    (:file "src/minerva/gui/button")
    (:file "src/minerva/gui/nine-patch")
     (:file "src/minerva/events")))

(asdf:defsystem "minerva/tests"
  :description "Minerva GUI and graphics tests"
  :depends-on ("minerva")
  :serial t
  :components
  ((:file "tests/minerva/gui/test-support")
   (:file "tests/minerva/gui/test-core")
   (:file "tests/minerva/gui/test-window")
   (:file "tests/minerva/gui/test-hbox")
   (:file "tests/minerva/gui/test-vbox")
   (:file "tests/minerva/gui/test-filler")
   (:file "tests/minerva/gui/test-image")
  (:file "tests/minerva/gui/test-label")
  (:file "tests/minerva/gui/test-button")
   (:file "tests/minerva/gui/test-color-rect")
   (:file "tests/minerva/gui/test-nine-patch")
   (:file "tests/minerva/gui/tests")
   (:file "tests/minerva/events/tests")
   (:file "tests/minerva/gfx/tests"))
  :perform (asdf:test-op (op component)
             (declare (ignore op component))
             (let ((run-gui-fn (find-symbol "RUN-GUI-LAYOUT-TESTS" :minerva.gui))
                   (run-events-fn (find-symbol "RUN-EVENT-TESTS" :minerva.events.tests))
                   (run-gfx-fn (find-symbol "RUN-GFX-RESOURCE-TESTS" :minerva.gfx.tests)))
               (unless (and run-gui-fn (fboundp run-gui-fn))
                 (error "RUN-GUI-LAYOUT-TESTS not found in MINERVA.GUI"))
               (unless (and run-events-fn (fboundp run-events-fn))
                 (error "RUN-EVENT-TESTS not found in MINERVA.EVENTS.TESTS"))
               (unless (and run-gfx-fn (fboundp run-gfx-fn))
                 (error "RUN-GFX-RESOURCE-TESTS not found in MINERVA.GFX.TESTS"))
               (funcall run-gui-fn)
               (funcall run-events-fn)
               (funcall run-gfx-fn))))
