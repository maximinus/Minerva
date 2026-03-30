;; Run from project root with: sbcl --script demos/menubar-demo.lisp
;; demonstrates milestone 7 MenuBar/MenuBarButton behavior

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-menubar-demo-ui (width height)
  (let ((menu-bar (make-instance 'minerva.gui:menu-bar
                                 :entries (list '(:text "File"
                                                  :items ((:text "New" :command :new-file)
                                                          (:text "Open" :command :open-file)
                                                          (:text "Save" :command :save-file)
                                                          :spacer
                                                          (:text "Quit" :command :quit-app)))
                                                '(:text "Edit"
                                                  :items ((:text "Undo" :command :undo)
                                                          (:text "Redo" :command :redo)
                                                          :spacer
                                                          (:text "Cut" :command :cut)
                                                          (:text "Copy" :command :copy)
                                                          (:text "Paste" :command :paste)))
                                                '(:text "Help"
                                                  :items ((:text "About" :command :about)))))))
    (make-instance 'minerva.gui:window
                   :width width
                   :height height
                   :child (make-instance 'minerva.gui:vbox
                                         :spacing 0
                                         :children (list menu-bar
                                                         (make-instance 'minerva.gui:color-rect
                                                                        :color '(36 40 48 255)
                                                                        :expand-x t
                                                                        :expand-y t))))))

(defun run-menubar-demo (&key (title "Minerva MenuBar Demo")
                              (width 900)
                              (height 600)
                              (max-runtime-ms 45000))
  (minerva.gfx:init-backend)
  (let ((backend-window nil)
        (app-state nil)
        (start-time 0))
    (unwind-protect
         (progn
           (setf backend-window (minerva.gfx:create-window :title title :width width :height height))
           (setf app-state (minerva.events:make-app-state :root (make-menubar-demo-ui width height)))
           (setf start-time (minerva.gfx:ticks-ms))

           (loop until (minerva.gfx:window-should-close-p backend-window) do
             (dolist (raw-event (minerva.gfx:poll-events))
               (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
                 (when event
                   (minerva.events:process-minerva-event app-state event)
                   (when (minerva.events:app-state-should-quit app-state)
                     (minerva.gfx:request-window-close backend-window)))))

             (let ((current-command (minerva.events:app-state-last-command app-state)))
               (when current-command
                 (format t "~&MenuBar emitted command: ~S~%" current-command)
                 (finish-output)
                 (setf (minerva.events:app-state-last-command app-state) nil)))

             (multiple-value-bind (window-width window-height)
                 (minerva.gfx:window-size backend-window)
               (let ((root (minerva.events:app-state-root app-state)))
                 (setf (minerva.gui:window-width root) window-width
                       (minerva.gui:window-height root) window-height)))

             (minerva.events:layout-app-state app-state)
             (minerva.gfx:begin-frame backend-window)
             (minerva.gfx:clear-screen backend-window
                                       (minerva.gfx:make-color :r 22 :g 24 :b 30 :a 255))
             (minerva.events:render-app-state app-state backend-window)
             (minerva.gfx:end-frame backend-window)

             (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
               (minerva.gfx:request-window-close backend-window))
             (minerva.gfx:sleep-ms 16)))
      (ignore-errors
        (when backend-window
          (minerva.gfx:destroy-window backend-window)))
      (ignore-errors (minerva.gfx:shutdown-backend)))))

(run-menubar-demo)
