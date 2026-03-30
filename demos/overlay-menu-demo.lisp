;; Run from project root with: sbcl --script demos/overlay-menu-demo.lisp
;; demonstrates milestone 6 overlay menu placement over base UI

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun demo-asset-path (path)
  (if (and (stringp path)
           (> (length path) 0)
           (char= (char path 0) #\/))
      (subseq path 1)
      path))

(defun make-overlay-menu-demo-root (width height)
  (make-instance 'minerva.gui:window
                 :width width
                 :height height
                 :background-color '(0 0 255 255)
                 :child (make-instance 'minerva.gui:color-rect
                                       :color '(0 255 0 255)
                                       :expand-x t
                                       :expand-y t
                                       :margins 120)))

(defun make-overlay-menu (icon-map)
  (make-instance 'minerva.gui:menu
                 :icon-resolver (lambda (icon-key)
                                  (cdr (assoc icon-key icon-map)))
                 :entries (list '(:text "Open" :command :open :icon :open :key "Ctrl-O" :text-size 20)
                                '(:text "Save" :command :save :icon :save :key "Ctrl-S" :text-size 20)
                                :spacer
                                '(:text "Exit" :command :quit-app :key "Ctrl-X" :text-size 20))))

(defun run-overlay-menu-demo (&key (title "Minerva Overlay Menu Demo")
                                   (width 1000)
                                   (height 700)
                                   (open-icon-path "/assets/icons/open.png")
                                   (save-icon-path "/assets/icons/save.png")
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
           (setf open-icon (minerva.gfx:load-surface (demo-asset-path open-icon-path))
                 save-icon (minerva.gfx:load-surface (demo-asset-path save-icon-path)))

           (let ((root (make-overlay-menu-demo-root width height))
                 (menu (make-overlay-menu (list (cons :open open-icon)
                                                (cons :save save-icon)))))
             (setf app-state (minerva.events:make-app-state :root root))
             (minerva.events:push-overlay
              app-state
              (minerva.events:make-overlay :root-widget menu
                                           :rect (minerva.gui:make-rect :x 200 :y 200 :width 0 :height 0))))

           (setf start-time (minerva.gfx:ticks-ms))

           (loop until (minerva.gfx:window-should-close-p backend-window) do
             (dolist (raw-event (minerva.gfx:poll-events))
               (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
                 (when event
                   (minerva.events:process-minerva-event app-state event)
                   (when (minerva.events:app-state-should-quit app-state)
                     (minerva.gfx:request-window-close backend-window)))))

             (multiple-value-bind (window-width window-height)
                 (minerva.gfx:window-size backend-window)
               (let ((root (minerva.events:app-state-root app-state)))
                 (setf (minerva.gui:window-width root) window-width
                       (minerva.gui:window-height root) window-height)))

             (minerva.events:layout-app-state app-state)
             (minerva.gfx:begin-frame backend-window)
             (minerva.gfx:clear-screen backend-window
                                       (minerva.gfx:make-color :r 0 :g 0 :b 0 :a 255))
             (minerva.events:render-app-state app-state backend-window)
             (minerva.gfx:end-frame backend-window)

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

(run-overlay-menu-demo)
