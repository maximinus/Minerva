;; Run from project root with: sbcl --script demos/blue-rectangle-demo.lisp
;; draws a blue rectangle in a window

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-blue-rectangle-demo (&key (title "Minerva") (width 800) (height 600) (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let ((window (minerva.gfx:create-window :title title :width width :height height))
        (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (event (minerva.gfx:poll-events))
             (when (eq (first event) :quit)
               (minerva.gfx:request-window-close window)))
           (minerva.gfx:begin-frame window)
           (minerva.gfx:clear-screen window (minerva.gfx:make-color :r 0 :g 0 :b 0 :a 255))
           (minerva.gfx:fill-rect window
                                  (minerva.gfx:make-rect :x 200 :y 150 :width 300 :height 180)
                                  (minerva.gfx:make-color :r 0 :g 64 :b 255 :a 255))
           (minerva.gfx:end-frame window)
           (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
             (minerva.gfx:request-window-close window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-blue-rectangle-demo)
