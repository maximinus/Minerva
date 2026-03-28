;; Run from project root with: sbcl --script demos/expand-hbox-margins-demo.lisp
;; draws 3 color-rects in with differing margins

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-expand-color (rgba margin)
  (make-instance 'minerva.gui:color-rect
                 :color rgba
                 :margins (minerva.gui:make-margins margin)
                 :expand-x t
                 :expand-y t))

(defun run-expand-hbox-margins-demo (&key (title "Minerva HBox Expand + Margins Demo")
                                          (width 800)
                                          (height 600)
                                          (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (root-widget (make-instance 'minerva.gui:window
              :size (minerva.common:make-size :width width :height height)
                                     :child (make-instance 'minerva.gui:hbox
                                                          :children (list
                                                                     (make-expand-color '(255 179 186 255) 0)
                                                                     (make-expand-color '(186 255 201 255) 25)
                          (make-expand-color '(255 223 186 255) 50)))))
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

(run-expand-hbox-margins-demo)
