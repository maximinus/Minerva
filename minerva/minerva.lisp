;; Run from project root with: sbcl --script minerva/minerva.lisp

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-minerva-root-ui (width height)
  (make-instance 'minerva.gui:window
                 :width width
                 :height height
                 :child (make-instance 'minerva.gui:hbox
                                       :children (list (make-instance 'minerva.gui:color-rect
                                                                      :color '(255 0 0 255)
                                                                      :expand-x t
                                                                      :expand-y t)
                                                       (make-instance 'minerva.gui:color-rect
                                                                      :color '(0 255 0 255)
                                                                      :expand-x t
                                                                      :expand-y t)
                                                       (make-instance 'minerva.gui:color-rect
                                                                      :color '(0 0 255 255)
                                                                      :expand-x t
                                                                      :expand-y t)))))

(defun run-minerva-app (&key (title "Minerva") (width 800) (height 600))
  (minerva.gfx:init-backend)
  (let ((backend-window nil)
        (ui-root (make-minerva-root-ui width height)))
    (unwind-protect
         (progn
           (setf backend-window (minerva.gfx:create-window :title title :width width :height height))
           (loop until (minerva.gfx:window-should-close-p backend-window) do
             (dolist (event (minerva.gfx:poll-events))
               (when (eq (first event) :quit)
                 (minerva.gfx:request-window-close backend-window)))
             (minerva.gfx:begin-frame backend-window)
             (minerva.gfx:clear-screen backend-window 0 0 0 255)
             (minerva.gui:layout ui-root (minerva.gui:make-rect :x 0 :y 0 :width width :height height))
             (minerva.gui:render ui-root backend-window)
             (minerva.gfx:end-frame backend-window)
             (minerva.gfx:sleep-ms 16)))
      (ignore-errors
        (when backend-window
          (minerva.gfx:destroy-window backend-window)))
      (ignore-errors (minerva.gfx:shutdown-backend)))))

(run-minerva-app)
