;; Run from project root with: sbcl --script demos/centered-label-demo.lisp
;; draws centered "Hello, World!" text label

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun run-centered-label-demo (&key (title "Minerva Centered Label Demo")
                                  (width 800)
                                  (height 600)
                                  (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (label-widget (make-instance 'minerva.gui:label
                                      :text "Hello, World!"
                                      :font-name "inconsolata"
                                      :text-size 32
                                      :color '(255 255 255 255)
                                      :alignment :center))
         (root-widget (make-instance 'minerva.gui:window
                                     :size (minerva.common:make-size :width width :height height)
                                     :child label-widget))
         (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (event (minerva.gfx:poll-events))
             (when (eq (first event) :quit)
               (minerva.gfx:request-window-close window)))

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

(run-centered-label-demo)
