;; Run from project root with: sbcl --script demos/button-demo.lisp
;; draws a centered button

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-button-demo (&key (title "Minerva Button Demo")
                          (width 800)
                          (height 600)
                          (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (button-widget (make-instance 'minerva.gui:button
                                       :text "Click Me"
                                       :font-name "inconsolata"
                                       :text-size 32
                                       :color '(255 120 120 255)
                                       :padding (minerva.common:make-size :width 14 :height 10)
                                       :alignment :center))
         (root-widget (make-instance 'minerva.gui:window
                                     :size (minerva.common:make-size :width width :height height)
                                     :background-color (minerva.gfx:make-color :r 221 :g 221 :b 221 :a 255)
                                     :child button-widget))
         (app-state (minerva.events:make-app-state :root root-widget))
         (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (raw-event (minerva.gfx:poll-events))
             (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
               (when event
                 (minerva.events:process-minerva-event app-state event)
                 (when (minerva.events:app-state-should-quit app-state)
                   (minerva.gfx:request-window-close window)))))

           (multiple-value-bind (window-width window-height)
               (minerva.gfx:window-size window)
             (setf (minerva.gui:window-size root-widget)
                   (minerva.common:make-size :width window-width :height window-height))
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
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-button-demo)
