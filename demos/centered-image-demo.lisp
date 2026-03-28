;; Run from project root with: sbcl --script demos/centered-image-demo.lisp
;; draws a image centered in a window

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-centered-image-demo (&key (title "Minerva Centered Image Demo")
                                  (width 800)
                                  (height 600)
                                  (max-runtime-ms 12000)
                                  (image-path "demos/assets/dog.png"))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (surface (minerva.gfx:load-surface image-path))
         (image-widget (make-instance 'minerva.gui:image
                                      :surface surface
                                      :alignment :center))
         (root-widget (make-instance 'minerva.gui:window
                                     :width width
                                     :height height
                                     :child image-widget))
        (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (event (minerva.gfx:poll-events))
             (when (eq (first event) :quit)
               (minerva.gfx:request-window-close window)))

           (multiple-value-bind (window-width window-height)
               (minerva.gfx:window-size window)
             (setf (minerva.gui:window-width root-widget) window-width
                   (minerva.gui:window-height root-widget) window-height)
             (minerva.gui:layout root-widget
                                 (minerva.gui:make-rect :x 0
                                                        :y 0
                                                        :width window-width
                                                        :height window-height))
             (minerva.gfx:begin-frame window)
             (minerva.gfx:clear-screen window (minerva.gfx:make-color :r 0 :g 0 :b 0 :a 255))
             (minerva.gui:render root-widget window)
             (minerva.gfx:end-frame window))

           (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
             (minerva.gfx:request-window-close window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-surface surface)
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-centered-image-demo)
