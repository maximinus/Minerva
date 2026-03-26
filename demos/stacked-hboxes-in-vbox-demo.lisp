;; Run from project root with: sbcl --script demos/stacked-hboxes-in-vbox-demo.lisp
;; draws 3 expanding hboxes stacked inside 1 expanding vbox

(load (merge-pathnames #P"../tools/tooling/demo-bootstrap.lisp"
                       (make-pathname :name nil :type nil :defaults (or *load-truename* *load-pathname*))))

(minerva.tooling.demo-bootstrap:load-minerva)

(defun make-expand-color (rgba)
  (make-instance 'minerva.gui:color-rect
                 :color rgba
                 :expand-x t
                 :expand-y t))

(defun make-expand-row (color-a color-b color-c)
  (make-instance 'minerva.gui:hbox
                 :spacing 20
                 :children (list (make-expand-color color-a)
                                 (make-expand-color color-b)
                                 (make-expand-color color-c))))

(defun run-stacked-hboxes-in-vbox-demo (&key (title "Minerva Stacked HBoxes in VBox Demo")
                                             (width 1000)
                                             (height 700)
                                             (max-runtime-ms 12000))
  (minerva.gfx:init-backend)
  (let* ((window (minerva.gfx:create-window :title title :width width :height height))
         (root-widget (make-instance 'minerva.gui:window
                                     :width width
                                     :height height
                                     :child (make-instance 'minerva.gui:vbox
                                                          :spacing 5
                                                          :children (list
                                                                     (make-expand-row '(255 102 102 255)
                                                                                      '(255 178 102 255)
                                                                                      '(255 255 102 255))
                                                                     (make-expand-row '(102 204 255 255)
                                                                                      '(153 153 255 255)
                                                                                      '(204 153 255 255))
                                                                     (make-expand-row '(102 255 178 255)
                                                                                      '(153 255 153 255)
                                                                                      '(255 153 204 255))))))
         (start-time (minerva.gfx:ticks-ms)))
    (unwind-protect
         (loop until (minerva.gfx:window-should-close-p window) do
           (dolist (event (minerva.gfx:poll-events))
             (when (eq (first event) :quit)
               (minerva.gfx:request-window-close window)))

           (multiple-value-bind (window-width window-height)
               (minerva.gfx:window-size window)
             (setf (minerva.gui:window-width root-widget) window-width
                   (minerva.gui:window-height root-widget) window-height)
             (minerva.gui:layout root-widget
                                 (minerva.gui:make-rect :x 0
                                                        :y 0
                                                        :width window-width
                                                        :height window-height))
             (minerva.gfx:begin-frame window)
             (minerva.gfx:clear-screen window 0 0 0 255)
             (minerva.gui:render root-widget window)
             (minerva.gfx:end-frame window))

           (when (> (- (minerva.gfx:ticks-ms) start-time) max-runtime-ms)
             (minerva.gfx:request-window-close window))
           (minerva.gfx:sleep-ms 16))
      (minerva.gfx:destroy-window window)
      (minerva.gfx:shutdown-backend))))

(run-stacked-hboxes-in-vbox-demo)
