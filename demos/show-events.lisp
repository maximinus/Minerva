;; Run from project root with: sbcl --script demos/show-events.lisp
;; opens a screen and prints minerva events to the terminal

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-show-events-demo (&key (title "Minerva Show Events Demo") (width 800) (height 600))
  (minerva.gfx:init-backend)
  (let ((window nil))
    (unwind-protect
         (progn
           (setf window (minerva.gfx:create-window :title title :width width :height height))
           (loop until (minerva.gfx:window-should-close-p window) do
             (dolist (raw-event (minerva.gfx:poll-events))
               (let ((event (minerva.events:sdl-event->minerva-event raw-event)))
                 (when event
                   (format t "~&~S~%" event)
                   (finish-output)
                   (when (eq (first event) :quit)
                     (minerva.gfx:request-window-close window)))))
             (minerva.gfx:begin-frame window)
             (minerva.gfx:clear-screen window (minerva.gfx:make-color :r 0 :g 0 :b 0 :a 255))
             (minerva.gfx:end-frame window)
             (minerva.gfx:sleep-ms 16)))
      (ignore-errors
        (when window
          (minerva.gfx:destroy-window window)))
      (ignore-errors (minerva.gfx:shutdown-backend)))))

(run-show-events-demo)
