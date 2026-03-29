;; Run from project root with: sbcl --script demos/menu-demo.lisp
;; demonstrates milestone 5 Menu/MenuItem/MenuSpacer behavior

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-solid-icon-surface (rgba)
  (let ((surface (minerva.gfx:create-surface :width 16 :height 16)))
    (minerva.gfx:fill-surface surface
                              (apply #'minerva.gfx:make-color
                                     (list :r (first rgba)
                                           :g (second rgba)
                                           :b (third rgba)
                                           :a (fourth rgba))))
    surface))

(defun make-menu-demo-ui (width height icon-map)
  (let* ((menu (make-instance 'minerva.gui:menu
                              :icon-resolver (lambda (icon-key)
                                               (cdr (assoc icon-key icon-map)))
                              :entries (list '(:text "Open" :command :open :icon :open :key "Ctrl-O" :text-size 20)
                                             '(:text "Save" :command :save :icon :save :key "Ctrl-S" :text-size 20)
                                             :spacer
                                             '(:text "Exit" :command :quit-app :key "Ctrl-X" :text-size 20)))))
    (declare (ignore width height))
    (setf (minerva.gui:widget-content-alignment menu) :center)
    (make-instance 'minerva.gui:window
                   :width width
                   :height height
                   :child menu)))

(defun run-menu-demo (&key (title "Minerva Menu Demo")
                        (width 800)
                        (height 600)
                        (max-runtime-ms 30000))
  (minerva.gfx:init-backend)
  (let ((backend-window nil)
        (open-icon nil)
        (save-icon nil)
        (app-state nil)
        (start-time 0))
    (unwind-protect
         (progn
           (setf backend-window (minerva.gfx:create-window :title title :width width :height height))
               (setf open-icon (make-solid-icon-surface '(88 200 120 255))
                 save-icon (make-solid-icon-surface '(110 160 255 255)))
           (setf app-state
                 (minerva.events:make-app-state
              :root (make-menu-demo-ui width
                       height
                       (list (cons :open open-icon)
                         (cons :save save-icon)))))
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
                 (format t "~&Menu emitted command: ~S~%" current-command)
                 (finish-output)
                 (setf (minerva.events:app-state-last-command app-state) nil)))

             (multiple-value-bind (window-width window-height)
                 (minerva.gfx:window-size backend-window)
               (let ((root (minerva.events:app-state-root app-state)))
                 (setf (minerva.gui:window-width root) window-width
                       (minerva.gui:window-height root) window-height)
                 (minerva.gui:layout root
                                     (minerva.gui:make-rect :x 0
                                                            :y 0
                                                            :width window-width
                                                            :height window-height))
                 (minerva.gfx:begin-frame backend-window)
                 (minerva.gfx:clear-screen backend-window
                                           (minerva.gfx:make-color :r 20 :g 20 :b 24 :a 255))
                 (minerva.gui:render root backend-window)
                 (minerva.gfx:end-frame backend-window)))

             (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
               (minerva.gfx:request-window-close backend-window))
             (minerva.gfx:sleep-ms 16)))
      (ignore-errors
        (when open-icon (minerva.gfx:destroy-surface open-icon))
        (when save-icon (minerva.gfx:destroy-surface save-icon)))
      (ignore-errors
        (when backend-window
          (minerva.gfx:destroy-window backend-window)))
      (ignore-errors (minerva.gfx:shutdown-backend)))))

(run-menu-demo)
