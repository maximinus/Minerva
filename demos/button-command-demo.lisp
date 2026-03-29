;; Run from project root with: sbcl --script demos/button-command-demo.lisp
;; demonstrates Phase 2 button command emission and centralized action processing

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-button-command-demo-ui (width height)
  (make-instance 'minerva.gui:window
                 :width width
                 :height height
                 :child (make-instance 'minerva.gui:button
                                       :text "Load"
                                       :command :load-file
                                       :font-name "inconsolata"
                                       :text-size 14
                                       :color '(0 0 00 255)
                                       :padding-x 8
                                       :padding-y 2
                                       :alignment :center)))

(defun run-button-command-demo (&key (title "Minerva Button Command Demo")
                                  (width 800)
                                  (height 600)
                                  (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let ((backend-window nil)
        (app-state nil)
        (last-command nil)
        (start-time 0))
    (unwind-protect
         (progn
           (setf backend-window (minerva.gfx:create-window :title title :width width :height height))
           (setf app-state (minerva.events:make-app-state :root (make-button-command-demo-ui width height)
                                                          :window-width width
                                                          :window-height height))
           (setf start-time (minerva.gfx:ticks-ms))
           (loop until (minerva.gfx:window-should-close-p backend-window) do
             (dolist (raw-event (minerva.gfx:poll-events))
               (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
                 (when event
                   (minerva.events:process-minerva-event app-state event)
                   (when (minerva.events:app-state-should-quit app-state)
                     (minerva.gfx:request-window-close backend-window)))))

             (let ((current-command (minerva.events:app-state-last-command app-state)))
               (unless (eq current-command last-command)
                 (when current-command
                   (format t "~&Button emitted command: ~S~%" current-command)
                   (finish-output))
                 (setf last-command current-command)))

             (when (minerva.events:app-state-needs-redraw app-state)
               (let ((root (minerva.events:app-state-root app-state))
                     (frame-width (minerva.events:app-state-window-width app-state))
                     (frame-height (minerva.events:app-state-window-height app-state)))
                 (minerva.gui:layout root (minerva.gui:make-rect :x 0 :y 0
                                                                 :width frame-width
                                                                 :height frame-height))
                 (minerva.gfx:begin-frame backend-window)
                 (minerva.gfx:clear-screen backend-window
                                           (minerva.gfx:make-color :r 28 :g 28 :b 36 :a 255))
                 (minerva.gui:render root backend-window)
                 (minerva.gfx:end-frame backend-window)
                 (setf (minerva.events:app-state-needs-redraw app-state) nil)))

             (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
               (minerva.gfx:request-window-close backend-window))
             (minerva.gfx:sleep-ms 16)))
      (ignore-errors
        (when backend-window
          (minerva.gfx:destroy-window backend-window)))
      (ignore-errors (minerva.gfx:shutdown-backend)))))

(run-button-command-demo)
