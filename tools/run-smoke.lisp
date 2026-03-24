(load (merge-pathnames #P"tooling/runner.lisp"
                       (make-pathname :name nil :type nil :defaults *load-truename*)))

(in-package :cl-user)

(minerva.tooling.runner:run-tool-mode
 :smoke
 (lambda ()
   (minerva.tooling.runner:load-minerva-asd)
   (minerva.tooling.runner:with-phase (:smoke)
     (asdf:load-system "minerva")
     (minerva.gfx:init-backend)
     (let ((window nil)
           (surface nil))
       (unwind-protect
            (progn
              (setf window (minerva.gfx:create-window :title "Minerva Smoke" :width 64 :height 64))
              (setf surface (minerva.gfx:create-surface :width 8 :height 8))
              (minerva.gfx:begin-frame window)
              (minerva.gfx:clear-screen window 0 0 0 255)
              (minerva.gfx:draw-surface window surface (minerva.gfx:make-position :x 2 :y 2))
              (minerva.gfx:end-frame window))
         (when surface
           (ignore-errors (minerva.gfx:destroy-surface surface)))
         (when window
           (ignore-errors (minerva.gfx:destroy-window window)))
         (ignore-errors (minerva.gfx:shutdown-backend))))))
 :default-exit 1)
