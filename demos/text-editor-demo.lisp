;; Run from project root with: sbcl --script demos/text-editor-demo.lisp
;; shows a single expanding text editor widget

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-text-editor-demo (&key (title "Minerva Text Editor Demo")
                               (width 800)
                               (height 600)
                               (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (editor-widget (make-instance 'minerva.gui:text-editor
                                       :text ""
                                       :expand-x t
                                       :expand-y t
                                       :margin-left 16
                                       :margin-right 16
                                       :margin-top 16
                                       :margin-bottom 16))
         (root-widget (make-instance 'minerva.gui:window
                                     :size (minerva.common:make-size :width width :height height)
                                     :child editor-widget))
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
             (minerva.events:layout-app-state app-state)
             (minerva.gfx:begin-frame window)
             (minerva.gfx:clear-screen window (minerva.gfx:make-color :r 24 :g 24 :b 24 :a 255))
             (minerva.events:render-app-state app-state window)
             (minerva.gfx:end-frame window))

           (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
             (minerva.gfx:request-window-close window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-text-editor-demo)
